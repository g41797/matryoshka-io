// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

// Ownership:
//
//  alloc.create × 5 ──► list (producer)
//       │ list.popFirst × 5
//       ▼
//  freeItem per node (consumer)

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = io;
    var list: std.DoublyLinkedList = .{};

    defer freeRemaining(&list, allocator);

    var i: i32 = 0;
    while (i < 5) : (i += 1) {
        var slot: Slot = null;
        try types.EventPolyHelper.create(allocator, &slot);
        types.EventPolyHelper.cast(slot.?).?.code = i;
        list.append(&slot.?.*.node);
        slot = null;
    }

    var sum: i32 = 0;
    while (list.popFirst()) |node| {
        const poly: *polynode.PolyNode = @fieldParentPtr("node", node);
        const ev: *types.Event = types.EventPolyHelper.cast(poly) orelse return error.CastFailed;
        sum += ev.*.code;
        helpers.freeItem(poly, allocator);
    }

    try helpers.expect(error.ProduceConsumeFailed, sum == 0 + 1 + 2 + 3 + 4, "wrong sum");
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
