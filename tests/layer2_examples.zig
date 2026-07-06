const layer2 = @import("examples").layer2;
const std = @import("std");

const allocator = std.testing.allocator;
const io = std.Io.Threaded.global_single_threaded.*.io();

test "53 - simple send-receive" {
    std.testing.log_level = .debug;
    layer2.simple_send_receive.simple_send_receive(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "54 - worker loop pattern" {
    std.testing.log_level = .debug;
    layer2.worker_loop.worker_loop_pattern(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "55 - OOB via send_oob" {
    std.testing.log_level = .debug;
    layer2.oob_signal.oob_via_send_oob(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "56 - pipeline" {
    std.testing.log_level = .debug;
    layer2.pipeline.pipeline(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "57 - request-response" {
    std.testing.log_level = .debug;
    layer2.request_response.request_response(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "58 - fan-in" {
    std.testing.log_level = .debug;
    layer2.fan_in.fan_in(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "59 - shutdown with remaining item cleanup" {
    std.testing.log_level = .debug;
    layer2.shutdown_cleanup.shutdown_with_remaining_item_cleanup(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "60 - batch processing" {
    std.testing.log_level = .debug;
    layer2.batch_processing.batch_processing(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "61 - fan-out" {
    std.testing.log_level = .debug;
    layer2.fan_out.fan_out(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "62 - shutdown via ShutdownCommand" {
    std.testing.log_level = .debug;
    layer2.shutdown_exit.shutdown_via_shutdowncommand(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}

test "97 - wake up all" {
    std.testing.log_level = .debug;
    layer2.wake_up_all.wake_blocked_receiver_without_a_message(allocator, io) catch |err| {
        std.log.err("example failed: {s}", .{@errorName(err)});
        return err;
    };
}
