// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

// Ownership:
//
//  Seed: N_ITEMS items pre-created and placed in pool free list.
//
//  worker1 ──pool.get_wait──► process ──pool.put──► pool
//  worker2 ──pool.get_wait──► process ──pool.put──► pool
//  worker3 ──pool.get_wait──► process ──pool.put──► pool
//  │
//  master: Select(MasterEvent) ──getWaitResult──► .pool_ev .item
//          re-spawn getWaitResult after each item
//          stop after N_ITEMS returned
//  │
//  sel.cancelDiscard() ──► pool.close ──► broadcast ──► workers exit (Closed/Canceled)
//                      ──► on_close ──► freeList
//
//  get_wait: workers block until an item is available; Closed/Canceled on pool.close = clean exit.

const N_ITEMS: usize = 3;

const MasterEvent = union(enum) {
    pool_ev: pool.PoolResult,
};

const WorkerCtx = struct {
    ph: PoolHandle,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    var slot: Slot = null;
    pool.get_wait(ctx.ph, types.EventPolyHelper.TAG, &slot, null) catch |err| switch (err) {
        error.Closed, error.Canceled => return,
        else => return err,
    };
    const ev: *types.Event = types.EventPolyHelper.cast(slot.?).?;
    std.log.info("worker: processing Event code={d}", .{ev.code});
    pool.put(ctx.ph, &slot);
}

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const ph: PoolHandle = try pool.new(io, allocator);
    var pool_ctx: helpers.AlwaysCreateCtx = .{ .alloc = allocator };
    const tags = [_]*const anyopaque{types.EventPolyHelper.TAG};
    try pool.init(ph, pool_ctx.poolHooks(&tags));
    defer {
        pool.close(ph);
        pool.destroy(ph, allocator);
    }

    // Seed pool with N_ITEMS items so workers have items to get_wait on.
    for (0..N_ITEMS) |_| {
        var slot: Slot = null;
        try pool.get(ph, types.EventPolyHelper.TAG, .new_only, &slot);
        pool.put(ph, &slot);
    }

    var ctx1: WorkerCtx = .{ .ph = ph };
    var ctx2: WorkerCtx = .{ .ph = ph };
    var ctx3: WorkerCtx = .{ .ph = ph };
    var w1 = try io.concurrent(workerFn, .{&ctx1});
    var w2 = try io.concurrent(workerFn, .{&ctx2});
    var w3 = try io.concurrent(workerFn, .{&ctx3});

    var buf: [4]MasterEvent = undefined;
    var sel: std.Io.Select(MasterEvent) = std.Io.Select(MasterEvent).init(io, &buf);
    try sel.concurrent(.pool_ev, pool.getWaitResult, .{ ph, types.EventPolyHelper.TAG, null });

    var returned: usize = 0;

    while (returned < N_ITEMS) {
        const event: MasterEvent = try sel.await();
        switch (event) {
            .pool_ev => |r| switch (r) {
                .item => |handle| {
                    var slot: Slot = handle;
                    defer pool.put(ph, &slot);
                    const ev: *types.Event = types.EventPolyHelper.cast(slot.?).?;
                    returned += 1;
                    std.log.info("master: pool item returned code={d} ({d}/{d})", .{ ev.code, returned, N_ITEMS });
                    if (returned < N_ITEMS) {
                        try sel.concurrent(.pool_ev, pool.getWaitResult, .{ ph, types.EventPolyHelper.TAG, null });
                    }
                },
                .closed, .canceled, .timeout, .not_created => break,
            },
        }
    }

    sel.cancelDiscard();

    try w1.await(io);
    try w2.await(io);
    try w3.await(io);

    try helpers.expect(error.SelectJobPoolFailed, returned == N_ITEMS, "not all jobs returned");
    std.log.info("done: {d} jobs processed by workers, master tracked all returns", .{returned});
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const pool = matryoshka.pool;
const polynode = matryoshka.polynode;
const Slot = polynode.Slot;
const PoolHandle = pool.PoolHandle;
const types = helpers.types;
