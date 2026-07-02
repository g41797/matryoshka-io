// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

// Ownership:
//
//  main ──Event×10 + ShutdownCommand──► mailbox
//       │
//  worker: receive (first item) ──► freeSlot
//          receive_batch (rest) ──► walk + freeItem
//          (ShutdownCommand in batch → exit)

const WorkerCtx = struct {
    mbh: MailboxHandle,
    alloc: std.mem.Allocator,
    first_count: usize = 0,
    batch_count: usize = 0,
};

fn batchWorkerFn(ctx: *WorkerCtx) void {
    while (true) {
        var slot: Slot = null;
        mailbox.receive(ctx.mbh, &slot, null) catch return;
        const poly: *PolyNode = slot.?;

        if (types.ShutdownCommandPolyHelper.identifyNodeAs(poly)) |_| {
            helpers.freeSlot(&slot, ctx.alloc);
            return;
        }

        helpers.freeSlot(&slot, ctx.alloc);
        ctx.first_count += 1;

        var batch: std.DoublyLinkedList = mailbox.receive_batch(ctx.mbh) catch return;
        while (batch.popFirst()) |node| {
            const bpoly: *PolyNode = @fieldParentPtr("node", node);
            if (types.ShutdownCommandPolyHelper.identifyNodeAs(bpoly)) |_| {
                helpers.freeItem(bpoly, ctx.alloc);
                return;
            }
            helpers.freeItem(bpoly, ctx.alloc);
            ctx.batch_count += 1;
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
    const t = try std.Thread.spawn(.{}, batchWorkerFn, .{&ctx});

    const n: usize = 10;
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var slot: Slot = null;
        defer types.EventPolyHelper.destroy(allocator, &slot);
        try types.EventPolyHelper.create(allocator, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = @intCast(i);
        try mailbox.send(mbh, &slot);
    }

    // Signal worker to stop — all n items are already queued before this.
    {
        var slot: Slot = null;
        defer types.ShutdownCommandPolyHelper.destroy(allocator, &slot);
        try types.ShutdownCommandPolyHelper.create(allocator, &slot);
        try mailbox.send(mbh, &slot);
    }

    t.join();

    const total = ctx.first_count + ctx.batch_count;
    std.log.info("batch: first={d} batch={d} total={d}", .{ ctx.first_count, ctx.batch_count, total });
    try helpers.expect(error.BatchProcessingFailed, total == n, "wrong total");
    try helpers.expect(error.BatchProcessingFailed, ctx.first_count > 0, "no items received as first");
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
