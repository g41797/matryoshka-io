// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Builder pattern.
///
/// - Builder wraps an allocator, no other state.
/// - createEvent / createSensor build a typed item into a Slot.
/// - identifyNodeAs recovers the typed pointer for field access.
/// - destroyByTag frees whichever type the Slot holds.
///
/// Ownership:
///
///  alloc.create ──► slot (non-null)
///       │
///  Builder.identifyNodeAs ──► field access (no transfer)
///       │
///  Builder.destroyByTag ──► slot = null (freed)
pub fn @"Builder pattern"(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = io;
    const b: Builder = .{ .alloc = allocator };

    {
        var slot: Slot = null;
        defer b.destroyByTag(&slot);
        try b.createEvent(100, &slot);
        const ev = types.EventPolyHelper.mustIdentifySlotAs(&slot);
        try helpers.expect(error.BuilderFailed, ev.code == 100, "wrong event code");
    }

    {
        var slot: Slot = null;
        defer b.destroyByTag(&slot);
        try b.createSensor(9.8, &slot);
        const sn = types.SensorPolyHelper.mustIdentifySlotAs(&slot);
        try helpers.expect(error.BuilderFailed, sn.value == 9.8, "wrong sensor value");
    }
}

pub const Builder = struct {
    alloc: std.mem.Allocator,

    pub fn createEvent(self: Builder, code: i32, slot: *Slot) !void {
        try types.EventPolyHelper.create(self.alloc, slot);
        types.EventPolyHelper.mustIdentifySlotAs(slot).code = code;
    }

    pub fn createSensor(self: Builder, value: f64, slot: *Slot) !void {
        try types.SensorPolyHelper.create(self.alloc, slot);
        types.SensorPolyHelper.mustIdentifySlotAs(slot).value = value;
    }

    pub fn destroyByTag(self: Builder, slot: *Slot) void {
        helpers.freeSlot(slot, self.alloc);
    }
};

const helpers = @import("helpers");
const polynode = @import("matryoshka").polynode;
const std = @import("std");
const Slot = polynode.Slot;
const types = helpers.types;
