// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    {
        const ev: *types.Event = try allocator.create(types.Event);
        errdefer allocator.destroy(ev);
        ev.* = .{ .code = 53 };
        types.EventPolyHelper.init(ev);
        var slot: Slot = &ev.poly;
        try mailbox.send(mbh, &slot);
    }

    {
        const sn: *types.Sensor = try allocator.create(types.Sensor);
        errdefer allocator.destroy(sn);
        sn.* = .{ .value = 5.3 };
        types.SensorPolyHelper.init(sn);
        var slot: Slot = &sn.poly;
        try mailbox.send(mbh, &slot);
    }

    {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, allocator);
        try mailbox.receive(mbh, &slot, 1_000_000_000);
        const ev_recv: *types.Event = types.EventPolyHelper.cast(slot.?) orelse return error.WrongTag;
        try helpers.expect(error.SimpleSendReceiveFailed, ev_recv.*.code == 53, "wrong event code");
        std.log.info("received Event code={d}", .{ev_recv.*.code});
    }

    {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, allocator);
        try mailbox.receive(mbh, &slot, 1_000_000_000);
        const sn_recv: *types.Sensor = types.SensorPolyHelper.cast(slot.?) orelse return error.WrongTag;
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
