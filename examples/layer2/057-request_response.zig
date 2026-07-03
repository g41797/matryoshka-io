// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Request-response.
///
/// - Main sends an Event (code=42) to the worker's request mailbox.
/// - Worker adds 1000 to the code, sends it to the response mailbox.
/// - Main receives the response, verifies the value.
///
/// Ownership:
///
///  main ──Event(code=42)──► req_mbh ──► worker
///                                          │ code += 1000
///                                          ▼
///  main ◄──Event(code=1042)── resp_mbh ◄── worker
pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const req_mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer mailbox.destroy(req_mbh, allocator);

    const resp_mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer mailbox.destroy(resp_mbh, allocator);

    var ctx: WorkerCtx = .{ .req_mbh = req_mbh, .resp_mbh = resp_mbh, .alloc = allocator };
    const t = try std.Thread.spawn(.{}, workerFn, .{&ctx});

    {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, allocator);
        try types.EventPolyHelper.create(allocator, &slot);
        types.EventPolyHelper.mustIdentifySlotAs(&slot).code = 42;
        try mailbox.send(req_mbh, &slot);
    }

    {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, allocator);
        try mailbox.receive(resp_mbh, &slot, 5_000_000_000);
        const resp: *types.Event = types.EventPolyHelper.identifySlotAs(&slot) orelse return error.WrongTag;
        std.log.info("request_response: response code={d}", .{resp.*.code});
        try helpers.expect(error.RequestResponseFailed, resp.*.code == 1042, "wrong response code");
    }

    var rem_req: std.DoublyLinkedList = mailbox.close(req_mbh);
    helpers.freeList(&rem_req, allocator);
    t.join();

    var rem_resp: std.DoublyLinkedList = mailbox.close(resp_mbh);
    helpers.freeList(&rem_resp, allocator);
}

const WorkerCtx = struct {
    req_mbh: MailboxHandle,
    resp_mbh: MailboxHandle,
    alloc: std.mem.Allocator,
};

fn workerFn(ctx: *WorkerCtx) void {
    while (true) {
        var slot: Slot = null;
        defer helpers.freeSlot(&slot, ctx.alloc);
        mailbox.receive(ctx.req_mbh, &slot, null) catch return;
        const ev: *types.Event = types.EventPolyHelper.identifySlotAs(&slot) orelse continue;
        std.log.debug("worker: request code={d}", .{ev.*.code});
        ev.*.code += 1000;
        mailbox.send(ctx.resp_mbh, &slot) catch {};
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
