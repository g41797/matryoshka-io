// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Shutdown with remaining item cleanup.
///
/// - Send 5 Events and 3 Sensors into a mailbox, none received.
/// - Close the mailbox — all items come back in the returned list.
/// - Walk the list with popFirst, free every item.
///
/// Ownership:
///
///  alloc.create × (n_events + n_sensors) ──► mailbox
///       │ mailbox.close (no receive — all items returned)
///       ▼
///  DoublyLinkedList ──► freeItem × N
pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer mailbox.destroy(mbh, allocator);

    const n_events: usize = 5;
    const n_sensors: usize = 3;

    var i: usize = 0;
    while (i < n_events) : (i += 1) {
        var slot: Slot = null;
        defer types.EventPolyHelper.destroy(allocator, &slot);
        try types.EventPolyHelper.create(allocator, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = @intCast(i);
        try mailbox.send(mbh, &slot);
    }

    i = 0;
    while (i < n_sensors) : (i += 1) {
        var slot: Slot = null;
        defer types.SensorPolyHelper.destroy(allocator, &slot);
        try types.SensorPolyHelper.create(allocator, &slot);
        types.SensorPolyHelper.mustIdentifySlotAs(&slot).value = @as(f64, @floatFromInt(i)) * 1.1;
        try mailbox.send(mbh, &slot);
    }

    // Close without receiving — all items come back in the returned list.
    var remaining: std.DoublyLinkedList = mailbox.close(mbh);
    var freed: usize = 0;
    while (remaining.popFirst()) |node| {
        helpers.freeItem(@fieldParentPtr("node", node), allocator);
        freed += 1;
    }

    std.log.info("shutdown cleanup: freed {d} items", .{freed});
    try helpers.expect(error.ShutdownCleanupFailed, freed == n_events + n_sensors, "wrong freed count");
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const polynode = matryoshka.polynode;
const mailbox = matryoshka.mailbox;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const types = helpers.types;
