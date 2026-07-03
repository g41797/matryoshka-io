// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Pool fan-in: many workers return.
///
/// - Seed the pool with N empty containers, one per worker mailbox.
/// - dispatch fills each container from the Master's job list, sends it to its worker.
/// - Each worker doubles the value, returns the container to the pool.
/// - collectResults reads all N results back from the pool, sums them.
///
/// Ownership:
///
///  Master job list: [{code=1},{code=2},{code=3}]
///  pool (3 empty containers seeded)
///  │
///  master: pool.get ──► fill from job list ──► mailbox.send ──► mbh[0..2]
///                                                                   │ worker[i] (io.concurrent)
///                                                                   │ mailbox.receive ──► process ──► pool.put ──► pool
///  master: fut[i].await ──► all workers done
///  master: pool.get ×3 ──► verify results
///  pool.close ──► on_close ──► freeList
///
///  Ownership: Master list → pool containers → worker mailboxes → workers → pool → master.
///  Pool items are empty containers: Master fills from job list, worker writes result back.
pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const master = try PoolFanInMaster.init(allocator, io);
    defer master.destroy();
    try master.run();
}

const N: usize = 3;

// Job descriptors — Master's own list, separate from pool containers.
const jobs = [N]i32{ 10, 20, 30 };

const WorkerCtx = struct {
    mbh: MailboxHandle,
    ph: PoolHandle,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    var slot: Slot = null;
    mailbox.receive(ctx.mbh, &slot, null) catch return;
    defer pool.put(ctx.ph, &slot); // return container to pool after processing
    const ev: *types.Event = types.EventPolyHelper.mustIdentifySlotAs(&slot);
    ev.code *= 2; // process: double the job value
    std.log.info("worker: processed job, result code={d}", .{ev.code});
}

const PoolFanInMaster = struct {
    fn run(self: *PoolFanInMaster) !void {
        try self.seedPool();
        try self.dispatch();
        try self.awaitWorkers();
        const total: usize, const result_sum: i32 = try self.collectResults();
        try helpers.expect(error.PoolFanInFailed, total == N, "expected N results in pool");
        try helpers.expect(error.PoolFanInFailed, result_sum == 120, "wrong result sum");
        std.log.info("fan-in: {d} results — Master list → pool → worker mailboxes → pool → master", .{total});
    }

    fn seedPool(self: *PoolFanInMaster) !void {
        for (0..N) |_| {
            var slot: Slot = null;
            try pool.get(self.ph, types.EventPolyHelper.TAG, .new_only, &slot);
            pool.put(self.ph, &slot);
        }
    }

    fn dispatch(self: *PoolFanInMaster) !void {
        for (0..N) |i| {
            var slot: Slot = null;
            try pool.get(self.ph, types.EventPolyHelper.TAG, .available_only, &slot);
            const ev: *types.Event = types.EventPolyHelper.mustIdentifySlotAs(&slot);
            ev.code = jobs[i];
            std.log.info("master: filled container with job code={d}, sending to worker {d}", .{ ev.code, i });
            try mailbox.send(self.mbhs[i], &slot);
        }
    }

    fn awaitWorkers(self: *PoolFanInMaster) !void {
        for (0..N) |i| try self.futs[i].await(self.io);
    }

    fn collectResults(self: *PoolFanInMaster) !struct { usize, i32 } {
        var total: usize = 0;
        var result_sum: i32 = 0;
        while (true) {
            var slot: Slot = null;
            pool.get(self.ph, types.EventPolyHelper.TAG, .available_only, &slot) catch break;
            defer helpers.freeSlot(&slot, self.allocator);
            const ev: *types.Event = types.EventPolyHelper.mustIdentifySlotAs(&slot);
            result_sum += ev.code;
            total += 1;
            std.log.info("master: result code={d}", .{ev.code});
        }
        return .{ total, result_sum };
    }

    allocator: std.mem.Allocator,
    io: std.Io,
    ph: PoolHandle,
    pool_ctx: helpers.AlwaysCreateCtx,
    tags: [1]*const anyopaque,
    mbhs: [N]MailboxHandle,
    ctxs: [N]WorkerCtx,
    futs: [N]std.Io.Future(anyerror!void),

    fn init(allocator: std.mem.Allocator, io: std.Io) !*PoolFanInMaster {
        const self = try allocator.create(PoolFanInMaster);
        errdefer allocator.destroy(self);
        self.allocator = allocator;
        self.io = io;
        self.pool_ctx = .{ .alloc = allocator };
        self.tags = .{types.EventPolyHelper.TAG};
        self.ph = try pool.new(io, allocator);
        errdefer {
            pool.close(self.ph);
            pool.destroy(self.ph, allocator);
        }
        try pool.init(self.ph, self.pool_ctx.poolHooks(&self.tags));
        var created: usize = 0;
        errdefer for (0..created) |i| {
            var rem: std.DoublyLinkedList = mailbox.close(self.mbhs[i]);
            helpers.freeList(&rem, allocator);
            mailbox.destroy(self.mbhs[i], allocator);
        };
        for (0..N) |i| {
            self.mbhs[i] = try mailbox.new(io, allocator);
            created += 1;
            self.ctxs[i] = .{ .mbh = self.mbhs[i], .ph = self.ph };
            self.futs[i] = try io.concurrent(workerFn, .{&self.ctxs[i]});
        }
        return self;
    }

    fn destroy(self: *PoolFanInMaster) void {
        for (0..N) |i| {
            var rem: std.DoublyLinkedList = mailbox.close(self.mbhs[i]);
            helpers.freeList(&rem, self.allocator);
            mailbox.destroy(self.mbhs[i], self.allocator);
        }
        pool.close(self.ph);
        pool.destroy(self.ph, self.allocator);
        self.allocator.destroy(self);
    }
};

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const mailbox = matryoshka.mailbox;
const pool = matryoshka.pool;
const polynode = matryoshka.polynode;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const PoolHandle = pool.PoolHandle;
const types = helpers.types;
