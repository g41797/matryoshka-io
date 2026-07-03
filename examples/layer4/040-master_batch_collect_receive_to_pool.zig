// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Master batch collect: receive_batch → put_all.
///
/// - Fill the mailbox with 5 items.
/// - batchDrainToPool: mailbox.receive_batch returns a std.DoublyLinkedList,
///   passed directly to pool.put_all — no per-item conversion.
/// - verifyPool confirms the pool has items after the transfer.
///
/// Ownership:
///
///  mailbox (5 items)
///  │
///  mailbox.receive_batch ──► std.DoublyLinkedList
///  pool.put_all ──► pool free-list (5 items recycled)
///  │
///  std.DoublyLinkedList flows from mailbox to pool without conversion.
///  pool.close ──► on_close ──► freeList
pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const ph: PoolHandle = try pool.new(io, allocator);
    var pool_ctx: helpers.AlwaysCreateCtx = .{ .alloc = allocator };
    const tags = [_]*const anyopaque{types.EventPolyHelper.TAG};
    try pool.init(ph, pool_ctx.poolHooks(&tags));
    defer {
        pool.close(ph);
        pool.destroy(ph, allocator);
    }

    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    try fillMailbox(mbh, allocator, N_ITEMS);
    std.log.info("mailbox: {d} items queued", .{N_ITEMS});

    try batchDrainToPool(ph, mbh);
    try verifyPool(ph);

    std.log.info("done: {d} items — mailbox.receive_batch → pool.put_all, no conversion needed", .{N_ITEMS});
}

const N_ITEMS: usize = 5;

fn fillMailbox(mbh: MailboxHandle, alloc: std.mem.Allocator, count: usize) !void {
    for (0..count) |i| {
        var slot: Slot = null;
        defer types.EventPolyHelper.destroy(alloc, &slot);
        try types.EventPolyHelper.create(alloc, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = @intCast(i + 1);
        try mailbox.send(mbh, &slot);
    }
}

fn batchDrainToPool(ph: PoolHandle, mbh: MailboxHandle) !void {
    var batch: std.DoublyLinkedList = try mailbox.receive_batch(mbh);
    pool.put_all(ph, &batch);
    std.log.info("receive_batch → put_all: stdlib list bridges mailbox to pool", .{});
}

fn verifyPool(ph: PoolHandle) !void {
    var slot: Slot = null;
    defer pool.put(ph, &slot);
    pool.get(ph, types.EventPolyHelper.TAG, .available_only, &slot) catch {
        return error.MasterBatchDrainFailed;
    };
    std.log.info("verified: pool has items after put_all", .{});
}

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
