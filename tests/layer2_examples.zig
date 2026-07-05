const layer2 = @import("examples").layer2;
const std = @import("std");

const allocator = std.testing.allocator;
const io = std.Io.Threaded.global_single_threaded.*.io();

test "53 - simple send-receive" {
    std.testing.log_level = .debug;
    layer2.simple_send_receive.@"Simple send-receive"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "54 - worker loop pattern" {
    std.testing.log_level = .debug;
    layer2.worker_loop.@"Worker loop pattern"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "55 - OOB via send_oob" {
    std.testing.log_level = .debug;
    layer2.oob_signal.@"OOB via send_oob"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "56 - pipeline" {
    std.testing.log_level = .debug;
    layer2.pipeline.Pipeline(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "57 - request-response" {
    std.testing.log_level = .debug;
    layer2.request_response.@"Request-response"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "58 - fan-in" {
    std.testing.log_level = .debug;
    layer2.fan_in.@"Fan-in"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "59 - shutdown with remaining item cleanup" {
    std.testing.log_level = .debug;
    layer2.shutdown_cleanup.@"Shutdown with remaining item cleanup"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "60 - batch processing" {
    std.testing.log_level = .debug;
    layer2.batch_processing.@"Batch processing"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "61 - fan-out" {
    std.testing.log_level = .debug;
    layer2.fan_out.@"Fan-out"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "62 - shutdown via ShutdownCommand" {
    std.testing.log_level = .debug;
    layer2.shutdown_exit.@"Shutdown via ShutdownCommand"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "97 - wake up all" {
    std.testing.log_level = .debug;
    layer2.wake_up_all.@"Wake blocked receiver without a message"(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}
