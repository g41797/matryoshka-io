// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Pool + Group: worker pool.
///
/// - Pool seeded with N empty containers, N workers spawned via Io.Group with a task index each.
/// - Each worker gets its own container, writes its index, returns it.
/// - group.cancel stops any workers still running, then pool.close frees the rest.
/// - No mailbox — each worker's own container is the coordination surface.
///
/// Ownership (mailbox-less):
///
///  pool (N_WORKERS empty containers seeded — code=0)
///  │ Io.Group (N_WORKERS workers, each with own task index at spawn time)
///  ├──► worker 0 ──pool.get──► slot (empty) ──► ev.code = 0 ──► pool.put ──► pool
///  ├──► worker 1 ──pool.get──► slot (empty) ──► ev.code = 1 ──► pool.put ──► pool
///  └──► worker 2 ──pool.get──► slot (empty) ──► ev.code = 2 ──► pool.put ──► pool
///  │
///  group.cancel ──► any worker that has not yet returned exits (all likely done)
///  pool.close ──► on_close ──► freeList (remaining items freed)
///
///  Work input: task index passed at spawn time. Pool item is an empty container.
///  Each worker gets its own container, writes its index, returns it. No mailbox needed.
pub fn @"Pool + Group: worker pool"(allocator: std.mem.Allocator, io: std.Io) !void {
    const ph: PoolHandle = try pool.new(io, allocator);
    var pool_ctx: helpers.AlwaysCreateCtx = .{ .alloc = allocator };
    const tags = [_]*const anyopaque{types.EventPolyHelper.TAG};
    try pool.init(ph, pool_ctx.poolHooks(&tags));

    try seedContainers(ph);

    var worker_ctxs: [N_WORKERS]WorkerCtx = undefined;
    var group: Io.Group = .init;
    try spawnWorkers(ph, io, &group, &worker_ctxs);

    std.log.info("master: {d} workers running, {d} empty containers in pool", .{ N_WORKERS, N_WORKERS });
    stopAndClosePool(ph, allocator, io, &group);
}

const N_WORKERS: usize = 3;

const WorkerCtx = struct {
    ph: PoolHandle,
    id: usize,
};

fn seedContainers(ph: PoolHandle) !void {
    for (0..N_WORKERS) |_| {
        var slot: Slot = null;
        try pool.get(ph, types.EventPolyHelper.TAG, .new_only, &slot);
        pool.put(ph, &slot);
    }
}

fn workerFn(ctx: *WorkerCtx) error{Canceled}!void {
    var slot: Slot = null;
    defer pool.put(ctx.ph, &slot);
    pool.get(ctx.ph, types.EventPolyHelper.TAG, .available_or_new, &slot) catch return;
    const ev: *types.Event = types.EventPolyHelper.mustIdentifySlotAs(&slot);
    ev.code = @intCast(ctx.id);
    std.log.info("worker {d}: wrote task index into empty container (code={d})", .{ ctx.id, ev.code });
}

fn spawnWorkers(ph: PoolHandle, io: std.Io, group: *Io.Group, ctxs: *[N_WORKERS]WorkerCtx) !void {
    for (ctxs, 0..) |*ctx, i| {
        ctx.* = .{ .ph = ph, .id = i };
        try group.concurrent(io, workerFn, .{ctx});
    }
}

fn stopAndClosePool(ph: PoolHandle, alloc: std.mem.Allocator, io: std.Io, group: *Io.Group) void {
    group.cancel(io);
    std.log.info("master: all workers stopped via group.cancel", .{});
    pool.close(ph);
    pool.destroy(ph, alloc);
    std.log.info("pool closed: on_close freed any remaining containers — no mailbox needed", .{});
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const pool = matryoshka.pool;
const polynode = matryoshka.polynode;
const Slot = polynode.Slot;
const PoolHandle = pool.PoolHandle;
const Io = std.Io;
const types = helpers.types;
