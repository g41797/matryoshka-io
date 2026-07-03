// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Mixed types through shared mailbox.
///
/// - Send one Event and one Sensor into the same mailbox.
/// - receiveAndDispatch pops both, dispatches on tag via identifyNodeAs.
/// - Verifies each payload, frees each item.
///
/// Ownership:
///
///  EventPolyHelper.create ──► slot ──► mailbox.send ──► mailbox
///  SensorPolyHelper.create ──► slot ──► mailbox.send ──► mailbox
///  │
///  mailbox.receive ──► slot (Event or Sensor)
///    dispatch on poly.tag:
///    == EventPolyHelper.TAG  ──► identifyNodeAs ──► *Event  ──► verify code==10 ──► freeSlot
///    == SensorPolyHelper.TAG ──► identifyNodeAs ──► *Sensor ──► verify value==3.14 ──► freeSlot
///  │
///  mailbox.close ──► freeList (empty: all received)
pub fn @"Mixed types through shared mailbox"(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    try sendEvent(mbh, allocator);
    try sendSensor(mbh, allocator);
    try receiveAndDispatch(mbh, allocator);
}

fn sendEvent(mbh: MailboxHandle, alloc: std.mem.Allocator) !void {
    var slot: Slot = null;
    defer types.EventPolyHelper.destroy(alloc, &slot);
    try types.EventPolyHelper.create(alloc, &slot);
    types.EventPolyHelper.mustIdentifySlotAs(&slot).code = 10;
    std.log.info("send: Event code={d}", .{10});
    try mailbox.send(mbh, &slot);
}

fn sendSensor(mbh: MailboxHandle, alloc: std.mem.Allocator) !void {
    var slot: Slot = null;
    defer types.SensorPolyHelper.destroy(alloc, &slot);
    try types.SensorPolyHelper.create(alloc, &slot);
    types.SensorPolyHelper.mustIdentifySlotAs(&slot).value = 3.14;
    std.log.info("send: Sensor value={d}", .{3.14});
    try mailbox.send(mbh, &slot);
}

fn receiveAndDispatch(mbh: MailboxHandle, alloc: std.mem.Allocator) !void {
    var event_ok: bool = false;
    var sensor_ok: bool = false;

    for (0..2) |_| {
        var slot: Slot = null;
        try mailbox.receive(mbh, &slot, null);
        defer helpers.freeSlot(&slot, alloc);
        const poly: *polynode.PolyNode = slot.?;
        if (types.EventPolyHelper.identifyNodeAs(poly)) |ev| {
            try helpers.expect(error.CrossLayerMixedTypesFailed, ev.code == 10, "wrong Event code");
            std.log.info("received: Event code={d}", .{ev.code});
            event_ok = true;
        } else if (types.SensorPolyHelper.identifyNodeAs(poly)) |sn| {
            try helpers.expect(error.CrossLayerMixedTypesFailed, sn.value == 3.14, "wrong Sensor value");
            std.log.info("received: Sensor value={d}", .{sn.value});
            sensor_ok = true;
        } else {
            return error.CrossLayerMixedTypesFailed;
        }
    }

    try helpers.expect(error.CrossLayerMixedTypesFailed, event_ok, "Event not received");
    try helpers.expect(error.CrossLayerMixedTypesFailed, sensor_ok, "Sensor not received");
    std.log.info("done: Event + Sensor through shared mailbox, dispatched on tag", .{});
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const mailbox = matryoshka.mailbox;
const polynode = matryoshka.polynode;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const types = helpers.types;
