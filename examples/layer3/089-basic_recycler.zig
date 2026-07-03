// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Basic recycler.
///
/// - Create a pool with hooks for the Event tag.
/// - pool.get with available_or_new allocates a fresh item.
/// - pool.put returns it, pool.get again recycles the same item.
/// - Verify the recycled item kept its data.
///
/// Ownership:
///
///  pool.get (available_or_new) ──► slot (new via on_get)
///       │ pool.put ──► pool (recycled)
///       │ pool.get (available_or_new) ──► slot (same item, data intact)
///       │ EventPolyHelper.destroy ──► freed
pub fn @"Basic recycler"(allocator: std.mem.Allocator, io: std.Io) !void {
    var ctx: helpers.AlwaysCreateCtx = .{ .alloc = allocator };
    const tags = [_]*const anyopaque{types.EventPolyHelper.TAG};

    const ph = try pool.new(io, allocator);
    defer {
        pool.close(ph);
        pool.destroy(ph, allocator);
    }
    try pool.init(ph, ctx.poolHooks(&tags));

    var slot: Slot = null;
    defer pool.put(ph, &slot);

    try pool.get(ph, types.EventPolyHelper.TAG, .available_or_new, &slot);
    const ev = types.EventPolyHelper.identifySlotAs(&slot) orelse return error.WrongTag;
    ev.code = 89;
    std.log.info("got fresh Event, set code={d}", .{ev.code});

    pool.put(ph, &slot);
    std.log.info("returned Event to pool", .{});

    try pool.get(ph, types.EventPolyHelper.TAG, .available_or_new, &slot);
    const ev2 = types.EventPolyHelper.identifySlotAs(&slot) orelse return error.WrongTag;
    std.log.info("recycled Event code={d}", .{ev2.code});
    try helpers.expect(error.BasicRecyclerFailed, ev2.code == 89, "recycled item lost its data");

    types.EventPolyHelper.destroy(allocator, &slot);
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const pool = matryoshka.pool;
const polynode = matryoshka.polynode;
const Slot = polynode.Slot;
const PoolHandle = pool.PoolHandle;
const types = helpers.types;
