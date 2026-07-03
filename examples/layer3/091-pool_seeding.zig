// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

/// Pool seeding.
///
/// - Seed the pool with 5 Sensor items via pool.get(new_only) + pool.put.
/// - Consume all 5 with pool.get(available_only) — no allocation.
/// - Free each consumed item, verify the count.
///
/// Ownership:
///
///  pool.get (new_only) × 5 ──► pool.put × 5
///  (pool holds 5 items)
///       │ pool.get (available_only) × 5
///       ▼
///  slot ──► SensorPolyHelper.destroy per item
pub fn run(allocator: std.mem.Allocator, io: std.Io) !void {
    var ctx: helpers.AlwaysCreateCtx = .{ .alloc = allocator };
    const tags = [_]*const anyopaque{types.SensorPolyHelper.TAG};

    const ph = try pool.new(io, allocator);
    defer {
        pool.close(ph);
        pool.destroy(ph, allocator);
    }
    try pool.init(ph, ctx.poolHooks(&tags));

    const n: usize = 5;

    // Seed: new_only forces allocation for each item.
    var i: usize = 0;
    while (i < n) : (i += 1) {
        var slot: Slot = null;
        defer pool.put(ph, &slot);
        try pool.get(ph, types.SensorPolyHelper.TAG, .new_only, &slot);
        const sn = types.SensorPolyHelper.mustIdentifySlotAs(&slot);
        sn.value = @as(f64, @floatFromInt(i)) * 0.1;
    }
    std.log.info("seeded {d} Sensor items into pool", .{n});

    // Consume: available_only takes pre-existing items — no allocation.
    var consumed: usize = 0;
    while (true) {
        var slot: Slot = null;
        defer types.SensorPolyHelper.destroy(allocator, &slot);
        pool.get(ph, types.SensorPolyHelper.TAG, .available_only, &slot) catch break;
        const sn = types.SensorPolyHelper.mustIdentifySlotAs(&slot);
        std.log.info("consumed Sensor value={d:.1}", .{sn.value});
        consumed += 1;
    }
    try helpers.expect(error.PoolSeedingFailed, consumed == n, "wrong consumed count");
}

const helpers = @import("helpers");
const matryoshka = @import("matryoshka");
const std = @import("std");
const pool = matryoshka.pool;
const polynode = matryoshka.polynode;
const Slot = polynode.Slot;
const PoolHandle = pool.PoolHandle;
const types = helpers.types;
