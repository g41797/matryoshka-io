// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Graceful shutdown with in-flight items.
///
/// - Master has 2 event sources: mailbox (Events + ShutdownCommand) and pool.
/// - eventLoop processes Events, then a ShutdownCommand triggers graceful shutdown.
/// - gracefulShutdown empties sel.cancel(), frees inbox items, recycles pool items.
/// - No item is lost across cancellation, at whatever stage each source was in.
///
/// Ownership:
///
///  mbh (Event items + ShutdownCommand)    pool (Event items)
///  │ receiveResult                         │ getWaitResult
///  └──────────────────────┬───────────────┘
///                         ▼
///                 Select(MasterEvent) ◄── sleepFn (timer)
///                         │ event loop
///                         ▼
///  .inbox .item (Event)   ──► process, re-spawn inbox
///  .inbox .item (Shutdown)──► initiate graceful shutdown:
///                              sel.cancel() loop
///                              .inbox  .item ──► freeSlot   (no item lost)
///                              .pool_ev .item──► pool.put    (no item lost)
///  sel.cancelDiscard() ──► pool.close ──► mailbox.close
pub fn @"Graceful shutdown with in-flight items"(allocator: std.mem.Allocator, io: std.Io) !void {
    const master = try GracefulShutdownMaster.init(allocator, io);
    defer master.destroy();
    try master.run();
}

const TIMER_NS: i96 = 30_000_000; // 30 ms
const N_EVENTS: usize = 2;

const MasterEvent = union(enum) {
    inbox: mailbox.ReceiveResult,
    pool_ev: pool.PoolResult,
    timer: void,
};

fn sleepFn(sleep_t: std.Io.Timeout, io: std.Io) void {
    std.Io.Timeout.sleep(sleep_t, io) catch {};
}

const GracefulShutdownMaster = struct {
    fn run(self: *GracefulShutdownMaster) !void {
        try self.seedResources();
        try self.eventLoop();
        self.gracefulShutdown();
        try helpers.expect(error.SelectGracefulShutdownFailed, self.shutdown_seen, "shutdown command not received");
        try helpers.expect(error.SelectGracefulShutdownFailed, self.events_processed == N_EVENTS, "events not all processed");
        std.log.info("done: events={d}, freed_inbox={d}, recycled_pool={d}", .{ self.events_processed, self.freed_inbox, self.recycled_pool });
    }

    fn seedResources(self: *GracefulShutdownMaster) !void {
        for (0..N_EVENTS) |i| {
            var slot: Slot = null;
            defer types.EventPolyHelper.destroy(self.allocator, &slot);
            try types.EventPolyHelper.create(self.allocator, &slot);
            types.EventPolyHelper.mustIdentifySlotAs(&slot).code = @intCast(i + 1);
            try mailbox.send(self.mbh, &slot);
        }
        {
            var slot: Slot = null;
            defer types.ShutdownCommandPolyHelper.destroy(self.allocator, &slot);
            try types.ShutdownCommandPolyHelper.create(self.allocator, &slot);
            try mailbox.send(self.mbh, &slot);
        }
        {
            var slot: Slot = null;
            try pool.get(self.ph, types.EventPolyHelper.TAG, .new_only, &slot);
            types.EventPolyHelper.mustIdentifySlotAs(&slot).code = 99;
            pool.put(self.ph, &slot);
        }
    }

    fn eventLoop(self: *GracefulShutdownMaster) !void {
        const sleep_t: std.Io.Timeout = .{
            .duration = .{ .raw = .{ .nanoseconds = TIMER_NS }, .clock = .real },
        };
        try self.sel.concurrent(.inbox, mailbox.receiveResult, .{ self.mbh, null });
        try self.sel.concurrent(.pool_ev, pool.getWaitResult, .{ self.ph, types.EventPolyHelper.TAG, null });
        try self.sel.concurrent(.timer, sleepFn, .{ sleep_t, self.io });

        outer: while (true) {
            const event: MasterEvent = try self.sel.await();
            switch (event) {
                .inbox => |r| switch (r) {
                    .item => |handle| {
                        if (types.EventPolyHelper.identifyNodeAs(handle)) |ev| {
                            var slot: Slot = handle;
                            defer helpers.freeSlot(&slot, self.allocator);
                            self.events_processed += 1;
                            std.log.info("inbox: Event code={d}", .{ev.code});
                            try self.sel.concurrent(.inbox, mailbox.receiveResult, .{ self.mbh, null });
                        } else if (types.ShutdownCommandPolyHelper.identifyNodeAs(handle)) |_| {
                            var slot: Slot = handle;
                            helpers.freeSlot(&slot, self.allocator);
                            std.log.info("inbox: ShutdownCommand — initiating graceful shutdown", .{});
                            self.shutdown_seen = true;
                            break :outer;
                        } else {
                            var slot: Slot = handle;
                            helpers.freeSlot(&slot, self.allocator);
                        }
                    },
                    .closed, .canceled, .timeout => break :outer,
                },
                .pool_ev => |r| switch (r) {
                    .item => |handle| {
                        var slot: Slot = handle;
                        defer pool.put(self.ph, &slot);
                        std.log.info("pool_ev: item received", .{});
                        try self.sel.concurrent(.pool_ev, pool.getWaitResult, .{ self.ph, types.EventPolyHelper.TAG, null });
                    },
                    .closed, .canceled, .timeout, .not_created => {},
                },
                .timer => {
                    std.log.info("timer: tick", .{});
                    try self.sel.concurrent(.timer, sleepFn, .{ sleep_t, self.io });
                },
            }
        }
    }

    fn gracefulShutdown(self: *GracefulShutdownMaster) void {
        while (self.sel.cancel()) |event| {
            switch (event) {
                .inbox => |r| switch (r) {
                    .item => |handle| {
                        var slot: Slot = handle;
                        helpers.freeSlot(&slot, self.allocator);
                        self.freed_inbox += 1;
                        std.log.info("graceful cancel: freed inbox item", .{});
                    },
                    .canceled, .closed, .timeout => {},
                },
                .pool_ev => |r| switch (r) {
                    .item => |handle| {
                        var slot: Slot = handle;
                        pool.put(self.ph, &slot);
                        self.recycled_pool += 1;
                        std.log.info("graceful cancel: recycled pool item", .{});
                    },
                    .canceled, .closed, .timeout, .not_created => {},
                },
                .timer => {},
            }
        }
    }

    allocator: std.mem.Allocator,
    io: std.Io,
    mbh: MailboxHandle,
    ph: PoolHandle,
    pool_ctx: helpers.AlwaysCreateCtx,
    tags: [1]*const anyopaque,
    events_processed: usize,
    shutdown_seen: bool,
    freed_inbox: usize,
    recycled_pool: usize,
    buf: [8]MasterEvent,
    sel: std.Io.Select(MasterEvent),

    fn init(allocator: std.mem.Allocator, io: std.Io) !*GracefulShutdownMaster {
        const self = try allocator.create(GracefulShutdownMaster);
        errdefer allocator.destroy(self);
        self.allocator = allocator;
        self.io = io;
        self.events_processed = 0;
        self.shutdown_seen = false;
        self.freed_inbox = 0;
        self.recycled_pool = 0;
        self.mbh = try mailbox.new(io, allocator);
        errdefer {
            var rem: std.DoublyLinkedList = mailbox.close(self.mbh);
            helpers.freeList(&rem, allocator);
            mailbox.destroy(self.mbh, allocator);
        }
        self.pool_ctx = .{ .alloc = allocator };
        self.tags = .{types.EventPolyHelper.TAG};
        self.ph = try pool.new(io, allocator);
        errdefer {
            pool.close(self.ph);
            pool.destroy(self.ph, allocator);
        }
        try pool.init(self.ph, self.pool_ctx.poolHooks(&self.tags));
        self.sel = std.Io.Select(MasterEvent).init(self.io, &self.buf);
        return self;
    }

    fn destroy(self: *GracefulShutdownMaster) void {
        var rem: std.DoublyLinkedList = mailbox.close(self.mbh);
        helpers.freeList(&rem, self.allocator);
        mailbox.destroy(self.mbh, self.allocator);
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
