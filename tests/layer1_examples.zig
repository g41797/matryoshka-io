const layer1 = @import("examples").layer1;
const std = @import("std");

const allocator = std.testing.allocator;
const io = std.Io.Threaded.global_single_threaded.*.io();

test "21 - define a PolyNode type" {
    std.testing.log_level = .debug;
    layer1.define_type.@"Define a PolyNode type"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "22 - ownership transfer via Slot" {
    std.testing.log_level = .debug;
    layer1.ownership_transfer.@"Ownership transfer via Slot"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "23 - tag-dispatch consume loop" {
    std.testing.log_level = .debug;
    layer1.tag_dispatch.@"Tag-dispatch consume loop"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "24 - builder pattern" {
    std.testing.log_level = .debug;
    layer1.builder.@"Builder pattern"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "25 - produce-consume with defer cleanup" {
    std.testing.log_level = .debug;
    layer1.produce_consume.@"Produce-consume with defer cleanup"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}
