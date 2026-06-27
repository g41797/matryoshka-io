const layer3 = @import("examples").layer3;
const std = @import("std");

const allocator = std.testing.allocator;
const io = std.Io.Threaded.global_single_threaded.*.io();

test "89 - basic recycler" {
    std.testing.log_level = .debug;
    layer3.basic_recycler.run(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "90 - capped pool" {
    std.testing.log_level = .debug;
    layer3.capped_pool.run(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "91 - pool seeding" {
    std.testing.log_level = .debug;
    layer3.pool_seeding.run(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "92 - pool teardown" {
    std.testing.log_level = .debug;
    layer3.pool_teardown.run(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}
