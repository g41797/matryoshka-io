// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

// Ownership:
//
//  master ──Event×3 + ShutdownCommand──► worker_mbh ──► worker thread
//                                                           │ process
//                                                           │ send worker_mbh ──► master_inbox
//                                                           ▼ exit
//  master ◄──worker_mbh (as NodeHandle)── master_inbox
//  master: close + destroy worker_mbh (tag+pointer verified first)

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
            slot = ctx.worker_mbh;
            mailbox.send(ctx.master_inbox, &slot) catch {};
            slot = null; // prevent defer from destroying the mailbox handle
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
    const master_inbox: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        _ = mailbox.close(master_inbox);
        mailbox.destroy(master_inbox, allocator);
    }

    const worker_mbh: MailboxHandle = try mailbox.new(io, allocator);

    var i: usize = 0;
    while (i < 3) : (i += 1) {
        var slot: Slot = null;
        defer types.EventPolyHelper.destroy(allocator, &slot);
        try types.EventPolyHelper.create(allocator, &slot);
        types.EventPolyHelper.cast(slot.?).?.code = @as(i32, @intCast(i + 1));
        try mailbox.send(worker_mbh, &slot);
    }

    {
        var slot: Slot = null;
        defer types.ShutdownCommandPolyHelper.destroy(allocator, &slot);
        try types.ShutdownCommandPolyHelper.create(allocator, &slot);
        try mailbox.send(worker_mbh, &slot);
    }

    std.log.info("master: sent 3 Events + ShutdownCommand to worker", .{});

    var ctx: WorkerCtx = .{
        .master_inbox = master_inbox,
        .worker_mbh = worker_mbh,
        .alloc = allocator,
    };
    const t = try std.Thread.spawn(.{}, workerFn, .{&ctx});

    var slot: Slot = null;
    defer if (slot) |mh| {
        _ = mailbox.close(mh);
        mailbox.destroy(mh, allocator);
    };
    try mailbox.receive(master_inbox, &slot, null);

    try helpers.expect(error.WorkerFinishFailed, mailbox.is_it_you(slot.?.*.tag), "expected a MailboxHandle");
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
