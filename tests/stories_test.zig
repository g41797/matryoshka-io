const stories = @import("stories");
const std = @import("std");
const testing = std.testing;
const Io = std.Io;

test "story: video transcoder — pool backpressure + StreamContext routing + Io.Group workers" {
    std.testing.log_level = .debug;
    var threaded: Io.Threaded = Io.Threaded.init(testing.allocator, .{});
    defer threaded.deinit();
    const tio: Io = threaded.io();
    stories.video_transcoder.run(testing.allocator, tio) catch |err| {
        std.log.err("story failed: {s}", .{@errorName(err)});
        return err;
    };
}
