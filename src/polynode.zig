// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

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

            /// Identifies a PolyNode as T.
            /// Returns null if the runtime tag does not match.
            /// Use in infrastructure code that works with *PolyNode directly.
            pub inline fn identifyNodeAs(node: *PolyNode) ?*T {
                if (node.tag != TAG)
                    return null;

                return @fieldParentPtr("poly", node);
            }

            /// Same as identifyNodeAs, but panics if the tag does not match.
            pub inline fn mustIdentifyNodeAs(node: *PolyNode) *T {
                return identifyNodeAs(node) orelse unreachable;
            }

            /// Identifies a Slot as T.
            /// Returns null if the Slot is empty or the tag does not match.
            /// Use in application code that works with Slots.
            pub inline fn identifySlotAs(slot: *const Slot) ?*T {
                const node = slot.* orelse return null;
                return identifyNodeAs(node);
            }

            /// Same as identifySlotAs, but panics if the Slot is empty or tag does not match.
            pub inline fn mustIdentifySlotAs(slot: *const Slot) *T {
                return identifySlotAs(slot) orelse unreachable;
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

                const object = Self.identifyNodeAs(poly);
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

            /// Identifies a PolyNode as T.
            /// Returns null if the runtime tag does not match.
            /// Use in infrastructure code that works with *PolyNode directly.
            pub inline fn identifyNodeAs(node: *PolyNode) ?*T {
                if (node.tag != TAG)
                    return null;

                return @fieldParentPtr("poly", node);
            }

            /// Same as identifyNodeAs, but panics if the tag does not match.
            pub inline fn mustIdentifyNodeAs(node: *PolyNode) *T {
                return identifyNodeAs(node) orelse unreachable;
            }

            /// Identifies a Slot as T.
            /// Returns null if the Slot is empty or the tag does not match.
            /// Use in application code that works with Slots.
            pub inline fn identifySlotAs(slot: *const Slot) ?*T {
                const node = slot.* orelse return null;
                return identifyNodeAs(node);
            }

            /// Same as identifySlotAs, but panics if the Slot is empty or tag does not match.
            pub inline fn mustIdentifySlotAs(slot: *const Slot) *T {
                return identifySlotAs(slot) orelse unreachable;
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

const std = @import("std");

