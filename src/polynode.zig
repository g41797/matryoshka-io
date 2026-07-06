// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Runtime type identity for intrusive list nodes.
//!
//! - Every type that flows through a mailbox or pool embeds a `PolyNode`.
//! - A `PolyNode` carries a runtime type tag and a list-node link.
//! - `PolyHelper(T)` generates the tag, identity checks, and casts for `T`.
//! - No custom list type: `PolyNode` embeds `std.DoublyLinkedList.Node`
//!   directly.

/// Marker type. Its address is the runtime tag for one PolyNode-based type.
pub const PolyTag = struct {
    _: u8 = 0,
};

/// Embedded in every PolyNode-based type.
///
/// Bridges a user type to Matryoshka infrastructure.
/// Infrastructure code sees only `*PolyNode`, never the user type.
pub const PolyNode = struct {
    node: std.DoublyLinkedList.Node = .{},
    tag: *const anyopaque = undefined,
};

/// Pointer to a PolyNode. Infrastructure code's view of a user item.
pub const NodeHandle = *PolyNode;

/// Optional NodeHandle. Null means empty.
pub const Slot = ?NodeHandle;

/// Clears intrusive link pointers.
///
/// Does not touch the runtime type tag.
/// Call after any list removal, before reusing or destroying the node.
/// `std.DoublyLinkedList` removal ops leave stale `prev`/`next` behind.
pub inline fn reset(node: *PolyNode) void {
    node.node.prev = null;
    node.node.next = null;
}

/// True if the node is currently linked into a list.
pub inline fn is_linked(node: *PolyNode) bool {
    return node.node.prev != null or node.node.next != null;
}

/// Generates tag identity and lifecycle functions for a PolyNode-based type.
///
/// `T` must have a field `poly: PolyNode` — compile error otherwise.
/// Replaces the manual tag/check/cast boilerplate with one call.
///
/// Two modes, selected by a declaration on `T`:
/// - Default: identity functions plus `create`/`destroy` (heap alloc/free of `T`).
/// - `T` declares `const no_create_destroy = void{}`: identity functions only.
///   For types that manage their own allocation, e.g. `_Mailbox`, `_Pool` —
///   generating `create`/`destroy` for them would be wrong.
pub fn PolyHelper(comptime T: type) type {
    comptime validatePolyType(T);

    if (!@hasDecl(T, "no_create_destroy")) {
        return struct {
            const Self = @This();

            var _tag: PolyTag = .{};

            /// Unique runtime type identifier.
            pub const TAG: *const anyopaque = &_tag;

            /// True if the tag belongs to T.
            pub inline fn isIt(tag: *const anyopaque) bool {
                return tag == TAG;
            }

            /// Casts a PolyNode to T if the tag matches.
            /// Null on tag mismatch. For infrastructure code holding *PolyNode directly.
            pub inline fn identifyNodeAs(node: *PolyNode) ?*T {
                if (node.tag != TAG)
                    return null;

                return @fieldParentPtr("poly", node);
            }

            /// Same as identifyNodeAs. Panics on tag mismatch.
            pub inline fn mustIdentifyNodeAs(node: *PolyNode) *T {
                return identifyNodeAs(node) orelse unreachable;
            }

            /// Casts a Slot to T if it holds a node and the tag matches.
            /// Null if the Slot is empty or the tag does not match. For application code.
            pub inline fn identifySlotAs(slot: *const Slot) ?*T {
                const node = slot.* orelse return null;
                return identifyNodeAs(node);
            }

            /// Same as identifySlotAs.
            /// Panics if the Slot is empty or the tag does not match.
            pub inline fn mustIdentifySlotAs(slot: *const Slot) *T {
                return identifySlotAs(slot) orelse unreachable;
            }

            /// Sets the embedded PolyNode's tag. Clears its list links.
            pub inline fn init(self: *T) void {
                self.poly = .{
                    .node = .{},
                    .tag = TAG,
                };
            }

            /// Allocates and initializes an object.
            ///
            /// Sends the new object into the Slot.
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

            /// Destroys the object the Slot points to.
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

                // Clears the Slot before the memory is released.
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

            /// True if the tag belongs to T.
            pub inline fn isIt(tag: *const anyopaque) bool {
                return tag == TAG;
            }

            /// Casts a PolyNode to T if the tag matches.
            /// Null on tag mismatch. For infrastructure code holding *PolyNode directly.
            pub inline fn identifyNodeAs(node: *PolyNode) ?*T {
                if (node.tag != TAG)
                    return null;

                return @fieldParentPtr("poly", node);
            }

            /// Same as identifyNodeAs. Panics on tag mismatch.
            pub inline fn mustIdentifyNodeAs(node: *PolyNode) *T {
                return identifyNodeAs(node) orelse unreachable;
            }

            /// Casts a Slot to T if it holds a node and the tag matches.
            /// Null if the Slot is empty or the tag does not match. For application code.
            pub inline fn identifySlotAs(slot: *const Slot) ?*T {
                const node = slot.* orelse return null;
                return identifyNodeAs(node);
            }

            /// Same as identifySlotAs.
            /// Panics if the Slot is empty or the tag does not match.
            pub inline fn mustIdentifySlotAs(slot: *const Slot) *T {
                return identifySlotAs(slot) orelse unreachable;
            }

            /// Sets the embedded PolyNode's tag. Clears its list links.
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

