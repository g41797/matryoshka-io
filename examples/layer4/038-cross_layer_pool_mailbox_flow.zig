// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pool + Mailbox flow.
//!
//! - getAndSend: pool.get fills an item, mailbox.send transfers it.
//! - receiveAndVerify: mailbox.receive gets it back, pool.put returns it.
//! - One ownership circuit, single-threaded — the minimal cross-layer flow.
//!
//!
//! ```
//!  pool.get ──► slot (code=7)
//!  mailbox.send ──► mailbox owns item
//!  mailbox.receive ──► slot (same item)
//!  pool.put ──► pool free-list
//!  pool.close ──► on_close ──► freed
//! ```
//!
//!  Pattern: pool → mailbox → pool. One ownership circuit, single-threaded.
//!

pub fn pool_mailbox_flow(allocator: std.mem.Allocator, io: std.Io) !void {
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

    var ctx: Ctx = .{ .ph = ph, .mbh = mbh, .alloc = allocator };
    try ctx.getAndSend();
    try ctx.receiveAndVerify();
}

const Ctx = struct {
    ph: PoolHandle,
    mbh: MailboxHandle,
    alloc: std.mem.Allocator,

    fn getAndSend(self: *Ctx) !void {
        var slot: Slot = null;
        defer types.EventPolyHelper.destroy(self.alloc, &slot);
        try pool.get(self.ph, types.EventPolyHelper.TAG, .new_only, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = 7;
        std.log.info("pool.get: code={d}", .{7});
        try mailbox.send(self.mbh, &slot);
    }

    fn receiveAndVerify(self: *Ctx) !void {
        var slot: Slot = null;
        try mailbox.receive(self.mbh, &slot, null);
        defer pool.put(self.ph, &slot);
        const ev: *types.Event = types.EventPolyHelper.mustIdentifySlotAs(&slot);
        try helpers.expect(error.CrossLayerFlowFailed, ev.code == 7, "wrong code after receive");
        std.log.info("mailbox.receive: code={d} — pool→mailbox→pool flow complete", .{ev.code});
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
