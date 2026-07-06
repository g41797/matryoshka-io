// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Simple send-receive.
//!
//! - One thread sends an Event, then a Sensor, into a mailbox.
//! - Same thread receives both back, in order.
//! - Verifies each roundtrip value.
//!
//!
//! ```
//!  alloc.create ──► slot ──mailbox.send──► mailbox (owns)
//!                                              │ mailbox.receive
//!                                              ▼
//!                                         slot ──► freeSlot
//! ```
//!

pub fn simple_send_receive(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, allocator);
        try types.EventPolyHelper.create(allocator, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = 53;
        try mailbox.send(mbh, &slot);
    }

    {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, allocator);
        try types.SensorPolyHelper.create(allocator, &slot);
        types.SensorPolyHelper.mustIdentifySlotAs(&slot).value = 5.3;
        try mailbox.send(mbh, &slot);
    }

    {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, allocator);
        try mailbox.receive(mbh, &slot, 1_000_000_000);
        const ev_recv: *types.Event = types.EventPolyHelper.identifySlotAs(&slot) orelse return error.WrongTag;
        try helpers.expect(error.SimpleSendReceiveFailed, ev_recv.*.code == 53, "wrong event code");
        std.log.info("received Event code={d}", .{ev_recv.*.code});
    }

    {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, allocator);
        try mailbox.receive(mbh, &slot, 1_000_000_000);
        const sn_recv: *types.Sensor = types.SensorPolyHelper.identifySlotAs(&slot) orelse return error.WrongTag;
        try helpers.expect(error.SimpleSendReceiveFailed, sn_recv.*.value == 5.3, "wrong sensor value");
        std.log.info("received Sensor value={d:.1}", .{sn_recv.*.value});
    }
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const polynode = matryoshka.polynode;
const mailbox = matryoshka.mailbox;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const types = helpers.types;
