// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Tag-dispatch consume loop.
//!
//! - Push one Event and one Sensor into a mixed-type list.
//! - Pop each node, check its tag.
//! - Recover the typed pointer with identifyNodeAs, process it.
//! - Free every item; count events and sensors separately.
//!
//!
//! ```
//!  alloc.create (Event) ──► list
//!  alloc.create (Sensor) ──► list
//!       │ list.popFirst
//!       ▼
//!  tag check ──► EventPolyHelper.identifyNodeAs or SensorPolyHelper.identifyNodeAs
//!       │ freeItem per node
//! ```
//!

pub fn tag_dispatch_consume_loop(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = io;
    var list: std.DoublyLinkedList = .{};

    defer freeRemaining(&list, allocator);

    {
        var slot: Slot = null;
        try types.EventPolyHelper.create(allocator, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = 7;
        list.append(&slot.?.*.node);
        slot = null;
    }

    {
        var slot: Slot = null;
        try types.SensorPolyHelper.create(allocator, &slot);
        types.SensorPolyHelper.mustIdentifySlotAs(&slot).value = 2.71;
        list.append(&slot.?.*.node);
        slot = null;
    }

    var processed_events: usize = 0;
    var processed_sensors: usize = 0;

    while (list.popFirst()) |node| {
        const poly: *polynode.PolyNode = @fieldParentPtr("node", node);

        if (types.EventPolyHelper.identifyNodeAs(poly)) |recovered_ev| {
            try helpers.expect(error.TagDispatchFailed, recovered_ev.*.code == 7, "wrong event code");
            processed_events += 1;
            helpers.freeItem(poly, allocator);
        } else if (types.SensorPolyHelper.identifyNodeAs(poly)) |recovered_sn| {
            try helpers.expect(error.TagDispatchFailed, recovered_sn.*.value == 2.71, "wrong sensor value");
            processed_sensors += 1;
            helpers.freeItem(poly, allocator);
        } else {
            return error.UnknownTag;
        }
    }

    try helpers.expect(error.TagDispatchFailed, processed_events == 1, "wrong event count");
    try helpers.expect(error.TagDispatchFailed, processed_sensors == 1, "wrong sensor count");
}

fn freeRemaining(list: *std.DoublyLinkedList, alloc: std.mem.Allocator) void {
    while (list.popFirst()) |node| {
        const poly: *polynode.PolyNode = @fieldParentPtr("node", node);
        helpers.freeItem(poly, alloc);
    }
}

const helpers = @import("helpers");
const polynode = @import("matryoshka").polynode;
const std = @import("std");
const Slot = polynode.Slot;
const types = helpers.types;
