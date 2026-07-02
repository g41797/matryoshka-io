// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

// Ownership:
//
//  pool (2 items)    mailbox (2 items)
//  │
//  mailbox.close ──► std.DoublyLinkedList ──► popFirst ──► freeItem (×2)
//  pool.close   ──► on_close ──► freeList (×2)
//  │
//  Entire shutdown: standard Zig stdlib — no Matryoshka-specific cleanup API.

const N_ITEMS: usize = 2;

fn seedMailbox(mbh: MailboxHandle, alloc: std.mem.Allocator, count: usize) !void {
    for (0..count) |i| {
        var slot: Slot = null;
        defer types.EventPolyHelper.destroy(alloc, &slot);
        try types.EventPolyHelper.create(alloc, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = @intCast(i + 1);
        try mailbox.send(mbh, &slot);
    }
}

fn seedPool(ph: PoolHandle, count: usize) !void {
    for (0..count) |i| {
        var slot: Slot = null;
        try pool.get(ph, types.EventPolyHelper.TAG, .new_only, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = @intCast(100 + i);
        pool.put(ph, &slot);
    }
}

fn closeMailbox(mbh: MailboxHandle, alloc: std.mem.Allocator) usize {
    var mbx_list: std.DoublyLinkedList = mailbox.close(mbh);
    var freed: usize = 0;
    while (mbx_list.popFirst()) |node| {
        const poly: *polynode.PolyNode = @fieldParentPtr("node", node);
        polynode.reset(poly);
        helpers.freeItem(poly, alloc);
        freed += 1;
    }
    mailbox.destroy(mbh, alloc);
    return freed;
}

fn closePool(ph: PoolHandle, alloc: std.mem.Allocator) void {
    pool.close(ph);
    pool.destroy(ph, alloc);
}

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const ph: PoolHandle = try pool.new(io, allocator);
    var pool_ctx: helpers.AlwaysCreateCtx = .{ .alloc = allocator };
    const tags = [_]*const anyopaque{types.EventPolyHelper.TAG};
    try pool.init(ph, pool_ctx.poolHooks(&tags));

    const mbh: MailboxHandle = try mailbox.new(io, allocator);

    try seedMailbox(mbh, allocator, N_ITEMS);
    try seedPool(ph, N_ITEMS);

    std.log.info("master: shutdown initiated — {d} in mailbox, {d} in pool", .{ N_ITEMS, N_ITEMS });

    const mbx_freed = closeMailbox(mbh, allocator);
    std.log.info("mailbox.close: freed {d} items via stdlib popFirst", .{mbx_freed});

    closePool(ph, allocator);
    std.log.info("pool.close: on_close freed {d} pool items", .{N_ITEMS});

    try helpers.expect(error.MasterShutdownFailed, mbx_freed == N_ITEMS, "mailbox freed count mismatch");
    std.log.info("done: master shutdown — stdlib walk, no Matryoshka-specific cleanup API", .{});
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
