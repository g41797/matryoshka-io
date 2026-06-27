// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

pub const Builder = struct {
    alloc: std.mem.Allocator,

    pub fn createEvent(self: Builder, code: i32, slot: *Slot) !void {
        try types.EventPolyHelper.create(self.alloc, slot);
        types.EventPolyHelper.cast(slot.*.?).?.code = code;
    }

    pub fn createSensor(self: Builder, value: f64, slot: *Slot) !void {
        try types.SensorPolyHelper.create(self.alloc, slot);
        types.SensorPolyHelper.cast(slot.*.?).?.value = value;
    }

    pub fn destroyByTag(self: Builder, slot: *Slot) void {
        helpers.freeSlot(slot, self.alloc);
    }
};

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = io;
    const b: Builder = .{ .alloc = allocator };

    {
        var slot: Slot = null;
        defer b.destroyByTag(&slot);
        try b.createEvent(100, &slot);
        const ev = types.EventPolyHelper.cast(slot.?).?;
        try helpers.expect(error.BuilderFailed, ev.code == 100, "wrong event code");
    }

    {
        var slot: Slot = null;
        defer b.destroyByTag(&slot);
        try b.createSensor(9.8, &slot);
        const sn = types.SensorPolyHelper.cast(slot.?).?;
        try helpers.expect(error.BuilderFailed, sn.value == 9.8, "wrong sensor value");
    }
}

const helpers = @import("helpers");
const polynode = @import("matryoshka").polynode;
const std = @import("std");
const Slot = polynode.Slot;
const types = helpers.types;
