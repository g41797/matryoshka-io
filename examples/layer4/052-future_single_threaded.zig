// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// ConcurrencyUnavailable on single-threaded.
///
/// - On a single-threaded Io backend, mailbox.receive_future returns error.ConcurrencyUnavailable.
/// - No concurrent task can be spawned to service the future.
/// - Synchronous mailbox.receive still works — it needs no concurrency.
///
/// Ownership:
///
///  mailbox (single-threaded io)
///  │
///  receive_future ──► error.ConcurrencyUnavailable
///  (no concurrent task can be spawned on single-threaded backend)
///  │
///  mailbox.receive (synchronous) still works
pub fn @"ConcurrencyUnavailable on single-threaded"(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    try testFutureUnavailable(mbh);
    try testSynchronousReceive(mbh, allocator);
}

fn testFutureUnavailable(mbh: MailboxHandle) !void {
    if (mailbox.receive_future(mbh, null)) |_| {
        return error.FutureSingleThreadedFailed;
    } else |_| {}
    std.log.info("receive_future: ConcurrencyUnavailable on single-threaded backend as expected", .{});
}

fn testSynchronousReceive(mbh: MailboxHandle, alloc: std.mem.Allocator) !void {
    var slot: Slot = null;
    defer types.EventPolyHelper.destroy(alloc, &slot);
    try types.EventPolyHelper.create(alloc, &slot);
    types.EventPolyHelper.mustIdentifySlotAs(&slot).code = 1;
    try mailbox.send(mbh, &slot);

    var received: Slot = null;
    defer helpers.freeSlot(&received, alloc);
    try mailbox.receive(mbh, &received, null);
    std.log.info("synchronous receive still works: code={d}", .{types.EventPolyHelper.mustIdentifySlotAs(&received).code});
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const mailbox = matryoshka.mailbox;
const polynode = matryoshka.polynode;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const types = helpers.types;
