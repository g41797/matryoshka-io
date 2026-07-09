const layer3 = @import("examples").layer3;
const std = @import("std");
const testing = std.testing;
const Io = std.Io;

const allocator = std.testing.allocator;

test "89 - basic recycler" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(testing.allocator, .{});
    defer threaded.deinit();
    const io: Io = threaded.io();
    layer3.basic_recycler.basic_recycler(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "90 - capped pool" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(testing.allocator, .{});
    defer threaded.deinit();
    const io: Io = threaded.io();
    layer3.capped_pool.backpressure_pool(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "91 - pool seeding" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(testing.allocator, .{});
    defer threaded.deinit();
    const io: Io = threaded.io();
    layer3.pool_seeding.pool_seeding(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "92 - pool teardown" {
    std.testing.log_level = .debug;
    var threaded: std.Io.Threaded = std.Io.Threaded.init(testing.allocator, .{});
    defer threaded.deinit();
    const io: Io = threaded.io();
    layer3.pool_teardown.pool_teardown(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}
