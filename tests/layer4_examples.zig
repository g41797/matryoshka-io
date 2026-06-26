const std = @import("std");
const layer4 = @import("examples").layer4;

const allocator = std.testing.allocator;
const io = std.Io.Threaded.global_single_threaded.*.io();

test "95 - worker finish signal via mailbox return" {
    std.testing.log_level = .debug;
    layer4.mailbox_as_item.run(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "96 - pool holds pools at teardown" {
    std.testing.log_level = .debug;
    layer4.pool_as_item.run(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}
