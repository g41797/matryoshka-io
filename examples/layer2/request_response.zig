// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

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
        const ev: *types.Event = types.EventPolyHelper.cast(slot.?) orelse continue;
        std.log.debug("worker: request code={d}", .{ev.*.code});
        ev.*.code += 1000;
        mailbox.send(ctx.resp_mbh, &slot) catch {};
    }
}

pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    const req_mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer mailbox.destroy(req_mbh, allocator);

    const resp_mbh: MailboxHandle = try mailbox.new(io, allocator);
    defer mailbox.destroy(resp_mbh, allocator);

    var ctx: WorkerCtx = .{ .req_mbh = req_mbh, .resp_mbh = resp_mbh, .alloc = allocator };
    const t = try std.Thread.spawn(.{}, workerFn, .{&ctx});

    const req: *types.Event = try allocator.create(types.Event);
    errdefer allocator.destroy(req);
    req.* = .{ .code = 42 };
    types.EventPolyHelper.init(req);
    var slot: Slot = &req.poly;
    try mailbox.send(req_mbh, &slot);

    {
        var resp_slot: Slot = null;
        defer helpers.freeSlot(&resp_slot, allocator);
        try mailbox.receive(resp_mbh, &resp_slot, 5_000_000_000);
        const resp: *types.Event = types.EventPolyHelper.cast(resp_slot.?) orelse return error.WrongTag;
        std.log.info("request_response: response code={d}", .{resp.*.code});
        try helpers.expect(error.RequestResponseFailed, resp.*.code == 1042, "wrong response code");
    }

    var rem_req: std.DoublyLinkedList = mailbox.close(req_mbh);
    helpers.freeList(&rem_req, allocator);
    t.join();

    var rem_resp: std.DoublyLinkedList = mailbox.close(resp_mbh);
    helpers.freeList(&rem_resp, allocator);
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const polynode = matryoshka.polynode;
const mailbox = matryoshka.mailbox;
const Slot = polynode.Slot;
const MailboxHandle = mailbox.MailboxHandle;
const types = helpers.types;
