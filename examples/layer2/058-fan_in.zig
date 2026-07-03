// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Fan-in.
///
/// - 3 concurrent senders: Events, Sensors, and a mixed sender.
/// - All send into one shared mailbox.
/// - Single receiver empties it with mailbox.receive_batch.
/// - Counts events and sensors received, verifies the total.
///
/// Ownership:
///
///  eventSenderFn ──Event×5──►
///  sensorSenderFn ──Sensor×5──► mailbox ──receive_batch──► freeItem per node
///  altSenderFn ──mixed×4──►
///  (3 concurrent senders fan-in to one mailbox)
pub fn @"Fan-in"(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    var ctx_ev: SenderCtx = .{ .mbh = mbh, .alloc = allocator };
    var ctx_sn: SenderCtx = .{ .mbh = mbh, .alloc = allocator };
    var ctx_alt: SenderCtx = .{ .mbh = mbh, .alloc = allocator };

    const t1 = try std.Thread.spawn(.{}, eventSenderFn, .{&ctx_ev});
    const t2 = try std.Thread.spawn(.{}, sensorSenderFn, .{&ctx_sn});
    const t3 = try std.Thread.spawn(.{}, altSenderFn, .{&ctx_alt});

    t1.join();
    t2.join();
    t3.join();

    const total_sent: usize = ctx_ev.sent + ctx_sn.sent + ctx_alt.sent;
    var batch: std.DoublyLinkedList = try mailbox.receive_batch(mbh);
    var events_received: usize = 0;
    var sensors_received: usize = 0;

    while (batch.popFirst()) |node| {
        const poly: *PolyNode = @fieldParentPtr("node", node);
        if (types.EventPolyHelper.identifyNodeAs(poly)) |_| {
            events_received += 1;
        } else if (types.SensorPolyHelper.identifyNodeAs(poly)) |_| {
            sensors_received += 1;
        }
        helpers.freeItem(poly, allocator);
    }

    std.log.info("fan-in: sent={d} events={d} sensors={d}", .{ total_sent, events_received, sensors_received });
    try helpers.expect(error.FanInFailed, events_received + sensors_received == total_sent, "wrong total");
}

const SenderCtx = struct {
    mbh: MailboxHandle,
    alloc: std.mem.Allocator,
    sent: usize = 0,
};

fn eventSenderFn(ctx: *SenderCtx) void {
    var i: i32 = 0;
    while (i < 5) : (i += 1) {
        var slot: Slot = null;
        types.EventPolyHelper.create(ctx.alloc, &slot) catch return;
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = i;
        mailbox.send(ctx.mbh, &slot) catch {
            helpers.freeSlot(&slot, ctx.alloc);
            return;
        };
        ctx.sent += 1;
    }
}

fn sensorSenderFn(ctx: *SenderCtx) void {
    var i: usize = 0;
    while (i < 5) : (i += 1) {
        var slot: Slot = null;
        types.SensorPolyHelper.create(ctx.alloc, &slot) catch return;
        types.SensorPolyHelper.mustIdentifySlotAs(&slot).value = @as(f64, @floatFromInt(i)) * 0.1;
        mailbox.send(ctx.mbh, &slot) catch {
            helpers.freeSlot(&slot, ctx.alloc);
            return;
        };
        ctx.sent += 1;
    }
}

fn altSenderFn(ctx: *SenderCtx) void {
    var i: i32 = 0;
    while (i < 4) : (i += 1) {
        var slot: Slot = null;
        if (@rem(i, 2) == 0) {
            types.EventPolyHelper.create(ctx.alloc, &slot) catch return;
            types.EventPolyHelper.mustIdentifySlotAs(&slot).code = 100 + i;
        } else {
            types.SensorPolyHelper.create(ctx.alloc, &slot) catch return;
            types.SensorPolyHelper.mustIdentifySlotAs(&slot).value = @as(f64, @floatFromInt(i));
        }
        mailbox.send(ctx.mbh, &slot) catch {
            helpers.freeSlot(&slot, ctx.alloc);
            return;
        };
        ctx.sent += 1;
    }
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const polynode = matryoshka.polynode;
const mailbox = matryoshka.mailbox;
const PolyNode = polynode.PolyNode;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const types = helpers.types;
