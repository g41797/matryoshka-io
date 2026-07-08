//! Just some shared test glue, not production code.
pub fn expect(comptime err: anyerror, ok: bool, comptime msg: []const u8) anyerror!void {
    if (!ok) {
        log.err("{s}", .{msg});
        return err;
    }
}

pub fn clearList(list: *std.DoublyLinkedList) void {
    while (list.popFirst()) |_| {}
}

const log = std.log;
const std = @import("std");
