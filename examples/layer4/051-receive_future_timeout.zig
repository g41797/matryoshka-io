// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// receive_future with timeout.
///
/// - receiveWithTimeout: receive_future on an empty mailbox with a 50ms timeout, resolves .timeout.
/// - sendAndReceiveItem: sends one Event, then receive_future(null) resolves .item.
/// - Confirms the future resolves to whichever result actually occurs.
///
/// Ownership:
///
///  mailbox (empty)
///  │
///  receive_future(50ms) ──► Future(ReceiveResult)
///  fut.await ──► ReceiveResult .timeout
///  │
///  EventPolyHelper.create ──► slot ──mailbox.send──► mailbox
///  receive_future(null) ──► fut.await ──► ReceiveResult .item ──► freeSlot
pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    var ctx: Ctx = .{ .mbh = mbh, .alloc = allocator, .io = io };
    try ctx.receiveWithTimeout();
    try ctx.sendAndReceiveItem();
}

const TIMEOUT_NS: u64 = 50_000_000; // 50 ms

const Ctx = struct {
    mbh: MailboxHandle,
    alloc: std.mem.Allocator,
    io: std.Io,

    fn receiveWithTimeout(self: *Ctx) !void {
        var fut_t: std.Io.Future(mailbox.ReceiveResult) = try mailbox.receive_future(self.mbh, TIMEOUT_NS);
        const r_timeout: mailbox.ReceiveResult = fut_t.await(self.io);
        try helpers.expect(error.ReceiveFutureTimeoutFailed, r_timeout == .timeout, "expected .timeout");
        std.log.info("receive_future timeout: got .timeout as expected", .{});
    }

    fn sendAndReceiveItem(self: *Ctx) !void {
        var slot: Slot = null;
        defer types.EventPolyHelper.destroy(self.alloc, &slot);
        try types.EventPolyHelper.create(self.alloc, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = 5;
        try mailbox.send(self.mbh, &slot);

        var fut_item: std.Io.Future(mailbox.ReceiveResult) = try mailbox.receive_future(self.mbh, null);
        const r_item: mailbox.ReceiveResult = fut_item.await(self.io);
        switch (r_item) {
            .item => |handle| {
                var received: Slot = handle;
                defer helpers.freeSlot(&received, self.alloc);
                std.log.info("receive_future after timeout: got Event code={d}", .{types.EventPolyHelper.mustIdentifySlotAs(&received).code});
            },
            else => return error.ReceiveFutureTimeoutFailed,
        }
    }
};

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const mailbox = matryoshka.mailbox;
const polynode = matryoshka.polynode;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const types = helpers.types;
