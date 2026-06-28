// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

// Ownership:
//
//  mailbox.send (Event×3) ──► queue tail
//  mailbox.send_oob (ShutdownCommand) ──► queue front
//       │ mailbox.receive ×4
//       ▼
//  OOB ShutdownCommand arrives first, then Events in send order
//  freeSlot per item

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    // Send 3 regular Event items.
    for (0..3) |i| {
        var slot: Slot = null;
        defer types.EventPolyHelper.destroy(allocator, &slot);
        try types.EventPolyHelper.create(allocator, &slot);
        types.EventPolyHelper.cast(slot.?).?.code = @intCast(i + 1);
        try mailbox.send(mbh, &slot);
    }

    // Send 1 OOB item (ShutdownCommand) — goes to front of queue.
    {
        var slot: Slot = null;
        defer types.ShutdownCommandPolyHelper.destroy(allocator, &slot);
        try types.ShutdownCommandPolyHelper.create(allocator, &slot);
        try mailbox.send_oob(mbh, &slot);
    }

    std.log.info("sent 3 Events (regular) + 1 ShutdownCommand (OOB)", .{});

    // Receive 4 items: OOB comes first, then regular items in order.
    var shutdown_seen: bool = false;
    var event_count: usize = 0;

    for (0..4) |_| {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, allocator);
        try mailbox.receive(mbh, &slot, null);
        const poly: *PolyNode = slot.?;

        if (types.ShutdownCommandPolyHelper.cast(poly)) |_| {
            try helpers.expect(error.OobOrderFailed, !shutdown_seen, "OOB ShutdownCommand must arrive before any Event");
            try helpers.expect(error.OobOrderFailed, event_count == 0, "OOB must be first item received");
            shutdown_seen = true;
            std.log.info("received OOB ShutdownCommand (first, as expected)", .{});
            helpers.freeSlot(&slot, allocator);
        } else if (types.EventPolyHelper.cast(poly)) |ev| {
            try helpers.expect(error.OobOrderFailed, shutdown_seen, "Events must arrive after the OOB item");
            event_count += 1;
            std.log.info("received Event code={d} (event {d}/3)", .{ ev.code, event_count });
            helpers.freeSlot(&slot, allocator);
        } else {
            return error.OobOrderFailed;
        }
    }

    try helpers.expect(error.OobOrderFailed, shutdown_seen, "OOB item not received");
    try helpers.expect(error.OobOrderFailed, event_count == 3, "expected 3 Events");

    std.log.info("OOB ordering verified: shutdown came first, then {d} events", .{event_count});
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
