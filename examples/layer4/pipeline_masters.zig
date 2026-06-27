// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

const ProducerCtx = struct {
    out_mbh: MailboxHandle,
    alloc: std.mem.Allocator,
};

fn producerFn(ctx: *ProducerCtx) anyerror!void {
    for (0..3) |i| {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, ctx.alloc);
        try types.EventPolyHelper.create(ctx.alloc, &slot);
        types.EventPolyHelper.cast(slot.?).?.code = @intCast(i + 1);
        try mailbox.send(ctx.out_mbh, &slot);
        std.log.info("producer: sent Event code={d}", .{i + 1});
    }
    {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, ctx.alloc);
        try types.ShutdownCommandPolyHelper.create(ctx.alloc, &slot);
        try mailbox.send(ctx.out_mbh, &slot);
        std.log.info("producer: sent ShutdownCommand sentinel", .{});
    }
}

const TransformerCtx = struct {
    in_mbh: MailboxHandle,
    out_mbh: MailboxHandle,
    alloc: std.mem.Allocator,
};

fn transformerFn(ctx: *TransformerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, ctx.alloc);
        mailbox.receive(ctx.in_mbh, &slot, null) catch return;
        const poly: *PolyNode = slot.?;

        if (types.EventPolyHelper.cast(poly)) |ev| {
            const value: f64 = @floatFromInt(ev.code);
            helpers.freeSlot(&slot, ctx.alloc);
            types.SensorPolyHelper.create(ctx.alloc, &slot) catch continue;
            types.SensorPolyHelper.cast(slot.?).?.value = value;
            mailbox.send(ctx.out_mbh, &slot) catch {
                helpers.freeSlot(&slot, ctx.alloc);
            };
            std.log.info("transformer: Event→Sensor value={d}", .{value});
        } else if (types.ShutdownCommandPolyHelper.cast(poly)) |_| {
            mailbox.send(ctx.out_mbh, &slot) catch {};
            std.log.info("transformer: forwarded ShutdownCommand, done", .{});
            return;
        } else {
            helpers.freeSlot(&slot, ctx.alloc);
        }
    }
}

const ConsumerCtx = struct {
    in_mbh: MailboxHandle,
    alloc: std.mem.Allocator,
    count: usize = 0,
};

fn consumerFn(ctx: *ConsumerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, ctx.alloc);
        mailbox.receive(ctx.in_mbh, &slot, null) catch return;
        const poly: *PolyNode = slot.?;

        if (types.SensorPolyHelper.cast(poly)) |sn| {
            ctx.count += 1;
            std.log.info("consumer: Sensor value={d} (total={d})", .{ sn.value, ctx.count });
            helpers.freeSlot(&slot, ctx.alloc);
        } else if (types.ShutdownCommandPolyHelper.cast(poly)) |_| {
            std.log.info("consumer: ShutdownCommand received, done", .{});
            helpers.freeSlot(&slot, ctx.alloc);
            return;
        } else {
            helpers.freeSlot(&slot, ctx.alloc);
        }
    }
}

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const transformer_mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(transformer_mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(transformer_mbh, allocator);
    }

    const consumer_mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(consumer_mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(consumer_mbh, allocator);
    }

    var prod_ctx: ProducerCtx = .{ .out_mbh = transformer_mbh, .alloc = allocator };
    var trans_ctx: TransformerCtx = .{
        .in_mbh = transformer_mbh,
        .out_mbh = consumer_mbh,
        .alloc = allocator,
    };
    var cons_ctx: ConsumerCtx = .{ .in_mbh = consumer_mbh, .alloc = allocator };

    var fut_prod = try io.concurrent(producerFn, .{&prod_ctx});
    var fut_trans = try io.concurrent(transformerFn, .{&trans_ctx});
    var fut_cons = try io.concurrent(consumerFn, .{&cons_ctx});

    try fut_prod.await(io);
    try fut_trans.await(io);
    try fut_cons.await(io);

    try helpers.expect(error.PipelineFailed, cons_ctx.count == 3, "expected consumer to receive 3 Sensors");

    std.log.info("pipeline done: consumer received {d} items", .{cons_ctx.count});
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
