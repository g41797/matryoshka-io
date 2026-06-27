// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

const WorkerCtx = struct {
    master_inbox: MailboxHandle,
    worker_mbh: MailboxHandle,
    alloc: std.mem.Allocator,
    processed: usize = 0,
};

fn workerFn(ctx: *WorkerCtx) void {
    while (true) {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, ctx.alloc);
        mailbox.receive(ctx.worker_mbh, &slot, null) catch return;
        const poly: *PolyNode = slot.?;

        if (types.ShutdownCommandPolyHelper.cast(poly) != null) {
            helpers.freeSlot(&slot, ctx.alloc);
            // Send our mailbox back to master — this IS the finish signal.
            var done: Slot = ctx.worker_mbh;
            mailbox.send(ctx.master_inbox, &done) catch {};
            return;
        }

        if (types.EventPolyHelper.cast(poly)) |ev| {
            ctx.processed += 1;
            std.log.info("worker processed Event code={d}", .{ev.code});
            helpers.freeSlot(&slot, ctx.alloc);
        }
    }
}

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    // Master's inbox — receives the finish signal (the worker's mailbox returned).
    const master_inbox: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        _ = mailbox.close(master_inbox);
        mailbox.destroy(master_inbox, allocator);
    }

    // Worker's mailbox — worker receives work items through this.
    // master_inbox will close+destroy it after receiving it back.
    const worker_mbh: MailboxHandle = try mailbox.new(io, allocator);

    // Send 3 Event items to worker.
    var i: usize = 0;
    while (i < 3) : (i += 1) {
        const ev: *types.Event = try allocator.create(types.Event);
        ev.* = .{};
        types.EventPolyHelper.init(ev);
        ev.code = @as(i32, @intCast(i + 1));
        var slot: Slot = &ev.poly;
        try mailbox.send(worker_mbh, &slot);
    }

    // Send shutdown sentinel.
    const cmd: *types.ShutdownCommand = try allocator.create(types.ShutdownCommand);
    cmd.* = .{};
    types.ShutdownCommandPolyHelper.init(cmd);
    var sentinel: Slot = &cmd.poly;
    try mailbox.send(worker_mbh, &sentinel);

    std.log.info("master: sent 3 Events + ShutdownCommand to worker", .{});

    // Spawn worker thread.
    var ctx: WorkerCtx = .{
        .master_inbox = master_inbox,
        .worker_mbh = worker_mbh,
        .alloc = allocator,
    };
    const t = try std.Thread.spawn(.{}, workerFn, .{&ctx});

    // Wait for worker to return its mailbox — the finish signal.
    var slot: Slot = null;
    defer if (slot) |mh| {
        _ = mailbox.close(mh);
        mailbox.destroy(mh, allocator);
    };
    try mailbox.receive(master_inbox, &slot, null);

    // Tag check: confirms it is a mailbox.
    try helpers.expect(error.WorkerFinishFailed, mailbox.is_it_you(slot.?.*.tag), "expected a MailboxHandle");

    // Pointer check: confirms it is the worker's mailbox specifically.
    try helpers.expect(error.WorkerFinishFailed, slot.? == worker_mbh, "wrong mailbox returned");

    std.log.info("master: received worker_mbh back — worker finished (processed={d})", .{ctx.processed});

    // Master owns cleanup of worker_mbh.
    const returned: MailboxHandle = slot.?;
    _ = mailbox.close(returned);
    mailbox.destroy(returned, allocator);
    slot = null;

    // Join thread — OS resource cleanup only.
    t.join();
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const mailbox = matryoshka.mailbox;
const polynode = matryoshka.polynode;
const PolyNode = polynode.PolyNode;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const types = helpers.types;
