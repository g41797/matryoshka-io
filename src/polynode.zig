// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

const std = @import("std");

pub const PolyTag = struct {
    _: u8 = 0,
};

pub const PolyNode = struct {
    node: std.DoublyLinkedList.Node = .{},
    tag: *const anyopaque = undefined,
};

pub const NodeHandle = *PolyNode;
pub const Slot = ?NodeHandle;

/// Clears intrusive links.
///
/// Does not modify the runtime type tag.
pub inline fn reset(node: *PolyNode) void {
    node.node.prev = null;
    node.node.next = null;
}

/// Returns true if the node is currently linked into an intrusive list.
pub inline fn is_linked(node: *PolyNode) bool {
    return node.node.prev != null or node.node.next != null;
}

pub fn PolyHelper(comptime T: type) type {
    comptime validatePolyType(T);

    if (!@hasDecl(T, "no_create_destroy")) {
        return struct {
            const Self = @This();

            var _tag: PolyTag = .{};

            /// Unique runtime type identifier.
            pub const TAG: *const anyopaque = &_tag;

            /// Returns true if the tag belongs to T.
            pub inline fn isIt(tag: *const anyopaque) bool {
                return tag == TAG;
            }

            /// Safely casts a PolyNode to T.
            /// Returns null if the runtime tag does not match.
            pub inline fn cast(node: *PolyNode) ?*T {
                if (node.tag != TAG)
                    return null;

                return @fieldParentPtr("poly", node);
            }

            /// Same as cast(), but requires the node to already be known as T.
            pub inline fn mustCast(node: *PolyNode) *T {
                return cast(node) orelse unreachable;
            }

            /// Initializes the embedded PolyNode.
            pub inline fn init(self: *T) void {
                self.poly = .{
                    .node = .{},
                    .tag = TAG,
                };
            }

            /// Allocates and initializes an object.
            ///
            /// Ownership is transferred into the Slot.
            pub fn create(
                allocator: std.mem.Allocator,
                slot: *Slot,
            ) !void {
                std.debug.assert(slot.* == null);

                const object = try allocator.create(T);
                object.* = .{};
                Self.init(object);

                slot.* = &object.poly;
            }

            /// Destroys the object owned by the Slot.
            ///
            /// A null Slot is ignored.
            pub fn destroy(
                allocator: std.mem.Allocator,
                slot: *Slot,
            ) void {
                const poly = slot.* orelse return;

                std.debug.assert(!is_linked(poly));

                const object = Self.cast(poly);
                std.debug.assert(object != null);

                // Ownership ends before memory is released.
                slot.* = null;

                allocator.destroy(object.?);
            }
        };
    } else {
        return struct {
            const Self = @This();

            var _tag: PolyTag = .{};

            /// Unique runtime type identifier.
            pub const TAG: *const anyopaque = &_tag;

            /// Returns true if the tag belongs to T.
            pub inline fn isIt(tag: *const anyopaque) bool {
                return tag == TAG;
            }

            /// Safely casts a PolyNode to T.
            /// Returns null if the runtime tag does not match.
            pub inline fn cast(node: *PolyNode) ?*T {
                if (node.tag != TAG)
                    return null;

                return @fieldParentPtr("poly", node);
            }

            /// Same as cast(), but requires the node to already be known as T.
            pub inline fn mustCast(node: *PolyNode) *T {
                return cast(node) orelse unreachable;
            }

            /// Initializes the embedded PolyNode.
            pub inline fn init(self: *T) void {
                self.poly = .{
                    .node = .{},
                    .tag = TAG,
                };
            }
        };
    }
}

fn validatePolyType(comptime T: type) void {
    if (!@hasField(T, "poly"))
        @compileError(@typeName(T) ++ ": missing field 'poly: PolyNode'");

    if (@FieldType(T, "poly") != PolyNode)
        @compileError(@typeName(T) ++ ": field 'poly' must have type PolyNode");
}
