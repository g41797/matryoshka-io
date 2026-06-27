// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

const TICK_NS: i96 = 20_000_000; // 20 ms
const N_EVENTS: usize = 3;
const N_TICKS: usize = 2;

const SenderCtx = struct {
    mbh: MailboxHandle,
    alloc: std.mem.Allocator,
    io: std.Io,
};

fn timerSenderFn(ctx: *SenderCtx) anyerror!void {
    const sleep_t: std.Io.Timeout = .{
        .duration = .{ .raw = .{ .nanoseconds = TICK_NS }, .clock = .real },
    };
    for (0..N_TICKS) |_| {
        try std.Io.Timeout.sleep(sleep_t, ctx.io);
        var slot: Slot = null;
        try types.TimerPolyHelper.create(ctx.alloc, &slot);
        mailbox.send(ctx.mbh, &slot) catch {
            helpers.freeSlot(&slot, ctx.alloc);
            return;
        };
    }
}

fn eventSenderFn(ctx: *SenderCtx) anyerror!void {
    for (0..N_EVENTS) |i| {
        var slot: Slot = null;
        try types.EventPolyHelper.create(ctx.alloc, &slot);
        types.EventPolyHelper.cast(slot.?).?.code = @intCast(i + 1);
        mailbox.send(ctx.mbh, &slot) catch {
            helpers.freeSlot(&slot, ctx.alloc);
            return;
        };
    }
}

fn signalSenderFn(ctx: *SenderCtx) anyerror!void {
    var slot: Slot = null;
    try types.ShutdownCommandPolyHelper.create(ctx.alloc, &slot);
    mailbox.send(ctx.mbh, &slot) catch helpers.freeSlot(&slot, ctx.alloc);
}

const WorkerCtx = struct {
    mbh: MailboxHandle,
    alloc: std.mem.Allocator,
    timer_count: usize = 0,
    event_count: usize = 0,
    signal_count: usize = 0,
};

fn workerFn(ctx: *WorkerCtx) anyerror!void {
    while (true) {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, ctx.alloc);
        mailbox.receive(ctx.mbh, &slot, null) catch return;

        if (types.TimerPolyHelper.cast(slot.?)) |_| {
            ctx.timer_count += 1;
            std.log.info("worker: timer tick {d}", .{ctx.timer_count});
        } else if (types.EventPolyHelper.cast(slot.?)) |ev| {
            ctx.event_count += 1;
            std.log.info("worker: Event code={d}", .{ev.code});
        } else if (types.ShutdownCommandPolyHelper.cast(slot.?)) |_| {
            ctx.signal_count += 1;
            std.log.info("worker: ShutdownCommand signal", .{});
        }
    }
}

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var rem: std.DoublyLinkedList = mailbox.close(mbh);
        helpers.freeList(&rem, allocator);
        mailbox.destroy(mbh, allocator);
    }

    var sender_ctx: SenderCtx = .{ .mbh = mbh, .alloc = allocator, .io = io };
    var worker_ctx: WorkerCtx = .{ .mbh = mbh, .alloc = allocator };

    var fut_timer = try io.concurrent(timerSenderFn, .{&sender_ctx});
    var fut_events = try io.concurrent(eventSenderFn, .{&sender_ctx});
    var fut_signal = try io.concurrent(signalSenderFn, .{&sender_ctx});
    var fut_worker = try io.concurrent(workerFn, .{&worker_ctx});

    // Wait for all senders to finish, then close mailbox to stop worker.
    fut_timer.await(io) catch {};
    fut_events.await(io) catch {};
    fut_signal.await(io) catch {};

    var remaining: std.DoublyLinkedList = mailbox.close(mbh);
    helpers.freeList(&remaining, allocator);

    fut_worker.await(io) catch {};

    std.log.info("done: {d} events, {d} timer ticks, {d} signals — fan-in to one mailbox", .{
        worker_ctx.event_count,
        worker_ctx.timer_count,
        worker_ctx.signal_count,
    });
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const mailbox = matryoshka.mailbox;
const polynode = matryoshka.polynode;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const types = helpers.types;
