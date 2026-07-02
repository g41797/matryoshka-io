// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

// Ownership:
//
//  main ──Event×3──► mailbox ──► worker (processes, freeSlot)
//  main ──ShutdownCommand──► mailbox ──► worker (exits, freeSlot)
//  (mailbox stays open; worker owns all received items)

const WorkerCtx = struct {
    mbh: MailboxHandle,
    alloc: std.mem.Allocator,
    processed: usize = 0,
};

fn workerFn(ctx: *WorkerCtx) void {
    while (true) {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, ctx.alloc);
        mailbox.receive(ctx.mbh, &slot, null) catch return;
        const poly: *PolyNode = slot.?;
        if (types.ShutdownCommandPolyHelper.identifyNodeAs(poly)) |_| {
            std.log.info("worker: ShutdownCommand received, exiting cleanly", .{});
            return;
        } else if (types.EventPolyHelper.identifyNodeAs(poly)) |ev| {
            std.log.debug("worker: Event code={d}", .{ev.*.code});
            ctx.processed += 1;
        } else if (types.SensorPolyHelper.identifyNodeAs(poly)) |sn| {
            std.log.debug("worker: Sensor value={d:.1}", .{sn.*.value});
            ctx.processed += 1;
        }
    }
}

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);

    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    var ctx: WorkerCtx = .{ .mbh = mbh, .alloc = allocator };
    const t = try std.Thread.spawn(.{}, workerFn, .{&ctx});

    const codes = [_]i32{ 10, 20, 30 };
    for (codes) |code| {
        var slot: Slot = null;
        defer types.EventPolyHelper.destroy(allocator, &slot);
        try types.EventPolyHelper.create(allocator, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = code;
        try mailbox.send(mbh, &slot);
    }

    // Send shutdown signal — mailbox stays open.
    {
        var slot: Slot = null;
        defer types.ShutdownCommandPolyHelper.destroy(allocator, &slot);
        try types.ShutdownCommandPolyHelper.create(allocator, &slot);
        try mailbox.send(mbh, &slot);
    }

    t.join();

    std.log.info("shutdown_exit: worker processed {d} items before ShutdownCommand", .{ctx.processed});
    try helpers.expect(error.ShutdownExitFailed, ctx.processed == 3, "wrong processed count");
}

const helpers = @import("helpers");
const types = helpers.types;
const matryoshka = @import("matryoshka");
const std = @import("std");
const polynode = matryoshka.polynode;
const mailbox = matryoshka.mailbox;
const PolyNode = polynode.PolyNode;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
