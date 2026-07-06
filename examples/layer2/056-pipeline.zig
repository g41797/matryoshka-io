// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Pipeline.
//!
//! - Chain of 3 stages: producer, transformer, consumer.
//! - Producer sends 5 Events, then a sentinel (code == -1).
//! - Transformer squares each code, forwards the sentinel, then exits.
//! - Consumer sums results, frees the sentinel, exits.
//!
//!
//! ```
//!  producer ──Event──► stage1 mailbox ──► transformer
//!                                              │ Event→Event (code²)
//!                                              ▼
//!  consumer ◄──Event── stage2 mailbox ◄── transformer
//!  (sentinel: Event code=-1 terminates each stage; consumer frees)
//! ```
//!

pub fn pipeline(allocator: std.mem.Allocator, io: std.Io) !void {
    const stage1: MailboxHandle = try mailbox.new(io, allocator);
    const stage2: MailboxHandle = try mailbox.new(io, allocator);
    defer {
        var r1: std.DoublyLinkedList = mailbox.close(stage1);
        helpers.freeList(&r1, allocator);
        var r2: std.DoublyLinkedList = mailbox.close(stage2);
        helpers.freeList(&r2, allocator);
        mailbox.destroy(stage1, allocator);
        mailbox.destroy(stage2, allocator);
    }

    var prod_ctx: ProducerCtx = .{ .outbox = stage1, .alloc = allocator };
    var tran_ctx: StageCtx = .{ .inbox = stage1, .outbox = stage2, .alloc = allocator };
    var cons_ctx: ConsumerCtx = .{ .mbh = stage2, .alloc = allocator };

    const t_prod = try std.Thread.spawn(.{}, producerFn, .{&prod_ctx});
    const t_tran = try std.Thread.spawn(.{}, transformerFn, .{&tran_ctx});
    const t_cons = try std.Thread.spawn(.{}, consumerFn, .{&cons_ctx});

    t_prod.join();
    t_tran.join();
    t_cons.join();

    // 0²+1²+2²+3²+4² = 30.
    std.log.info("pipeline: count={d} sum={d}", .{ cons_ctx.count, cons_ctx.sum });
    try helpers.expect(error.PipelineFailed, cons_ctx.count == 5, "wrong item count");
    try helpers.expect(error.PipelineFailed, cons_ctx.sum == 30, "wrong sum");
}

const ProducerCtx = struct {
    outbox: MailboxHandle,
    alloc: std.mem.Allocator,
};

fn producerFn(ctx: *ProducerCtx) void {
    var i: i32 = 0;
    while (i < 5) : (i += 1) {
        var slot: Slot = null;
        types.EventPolyHelper.create(ctx.alloc, &slot) catch return;
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = i;
        mailbox.send(ctx.outbox, &slot) catch {
            helpers.freeSlot(&slot, ctx.alloc);
            return;
        };
    }
    {
        var slot: Slot = null;
        types.EventPolyHelper.create(ctx.alloc, &slot) catch return;
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = -1;
        mailbox.send(ctx.outbox, &slot) catch helpers.freeSlot(&slot, ctx.alloc);
    }
}

const StageCtx = struct {
    inbox: MailboxHandle,
    outbox: MailboxHandle,
    alloc: std.mem.Allocator,
};

fn transformerFn(ctx: *StageCtx) void {
    while (true) {
        var slot: Slot = null;
        mailbox.receive(ctx.inbox, &slot, null) catch return;
        const ev: *types.Event = types.EventPolyHelper.identifySlotAs(&slot) orelse {
            helpers.freeSlot(&slot, ctx.alloc);
            continue;
        };
        if (ev.code == -1) {
            mailbox.send(ctx.outbox, &slot) catch helpers.freeSlot(&slot, ctx.alloc);
            return;
        }
        ev.code = ev.code * ev.code;
        mailbox.send(ctx.outbox, &slot) catch helpers.freeSlot(&slot, ctx.alloc);
    }
}

const ConsumerCtx = struct {
    mbh: MailboxHandle,
    alloc: std.mem.Allocator,
    sum: i32 = 0,
    count: usize = 0,
};

fn consumerFn(ctx: *ConsumerCtx) void {
    while (true) {
        var slot: Slot = null;
        mailbox.receive(ctx.mbh, &slot, null) catch return;
        const ev: *types.Event = types.EventPolyHelper.identifySlotAs(&slot) orelse {
            helpers.freeSlot(&slot, ctx.alloc);
            continue;
        };
        if (ev.code == -1) {
            helpers.freeSlot(&slot, ctx.alloc);
            return;
        }
        std.log.info("pipeline: result={d}", .{ev.code});
        ctx.sum += ev.code;
        ctx.count += 1;
        helpers.freeSlot(&slot, ctx.alloc);
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
