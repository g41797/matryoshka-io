// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Runtime type support for intrusive objects.
//!
//! Every Matryoshka object embeds a PolyNode.
//!
//! PolyNode provides:
//! - intrusive list links
//! - runtime type identity
//!
//! PolyHelper(T) generates the helper functions for T.
//!

const _doc_stub = void;

/// Runtime type marker.
///
/// Each PolyNode-based type has one.
/// Its address is the runtime type ID.
pub const PolyTag = struct {
    _: u8 = 0,
};

/// Embedded in every managed object.
///
/// Infrastructure works with PolyNode.
/// Applications work with the parent object.
pub const PolyNode = struct {
    node: std.DoublyLinkedList.Node = .{},
    tag: *const anyopaque = undefined,
};

/// Pointer to a PolyNode.
pub const ItemHandle = *PolyNode;

/// Optional item pointer.
pub const Slot = ?ItemHandle;

/// Clears the intrusive list links.
///
/// Call after removing a node from a list.
pub inline fn reset(node: *PolyNode) void {
    node.node.prev = null;
    node.node.next = null;
}

/// True if the node belongs to a list.
pub inline fn is_linked(node: *PolyNode) bool {
    return node.node.prev != null or node.node.next != null;
}

/// Generates runtime type support for `T`.
///
/// `T` must contain:
///
/// ```zig
/// poly: PolyNode
/// ```
///
/// Generated functions:
/// - runtime type ID
/// - type checks
/// - safe casts
/// - initialization
///
/// By default also generates:
/// - create()
/// - destroy()
///
/// Disable allocation helpers with:
///
/// ```zig
/// const no_create_destroy = void{};
/// ```
pub fn PolyHelper(comptime T: type) type {
    comptime validatePolyType(T);

    if (!@hasDecl(T, "no_create_destroy")) {
        return struct {
            const Self = @This();

            var _tag: PolyTag = .{};

            /// Runtime type ID.
            pub const TAG: *const anyopaque = &_tag;

            /// True if the tag belongs to T.
            pub inline fn isIt(tag: *const anyopaque) bool {
                return tag == TAG;
            }

            /// Casts a PolyNode to T.
            ///
            /// Returns null on type mismatch.
            pub inline fn identifyNodeAs(node: *PolyNode) ?*T {
                if (node.tag != TAG)
                    return null;

                return @fieldParentPtr("poly", node);
            }

            /// Same as identifyNodeAs().
            ///
            /// Panics on type mismatch.
            pub inline fn mustIdentifyNodeAs(node: *PolyNode) *T {
                return identifyNodeAs(node) orelse unreachable;
            }

            /// Casts a Slot to T.
            ///
            /// Returns null if the Slot is empty or has another type.
            pub inline fn identifySlotAs(slot: *const Slot) ?*T {
                const node = slot.* orelse return null;
                return identifyNodeAs(node);
            }

            /// Same as identifySlotAs().
            ///
            /// Panics on failure.
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

            /// Allocates and initializes T.
            ///
            /// Stores the object in the Slot.
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

            /// Destroys the object stored in the Slot.
            ///
            /// Does nothing if the Slot is empty.
            pub fn destroy(
                allocator: std.mem.Allocator,
                slot: *Slot,
            ) void {
                const poly = slot.* orelse return;

                std.debug.assert(!is_linked(poly));

                const object = Self.identifyNodeAs(poly);
                std.debug.assert(object != null);

                // Clear the Slot before releasing the object.
                slot.* = null;

                allocator.destroy(object.?);
            }
        };
    } else {
        return struct {
            const Self = @This();

            var _tag: PolyTag = .{};

            /// Runtime type ID.
            pub const TAG: *const anyopaque = &_tag;

            /// True if the tag belongs to T.
            pub inline fn isIt(tag: *const anyopaque) bool {
                return tag == TAG;
            }

            /// Casts a PolyNode to T.
            ///
            /// Returns null on type mismatch.
            pub inline fn identifyNodeAs(node: *PolyNode) ?*T {
                if (node.tag != TAG)
                    return null;

                return @fieldParentPtr("poly", node);
            }

            /// Same as identifyNodeAs().
            ///
            /// Panics on type mismatch.
            pub inline fn mustIdentifyNodeAs(node: *PolyNode) *T {
                return identifyNodeAs(node) orelse unreachable;
            }

            /// Casts a Slot to T.
            ///
            /// Returns null if the Slot is empty or has another type.
            pub inline fn identifySlotAs(slot: *const Slot) ?*T {
                const node = slot.* orelse return null;
                return identifyNodeAs(node);
            }

            /// Same as identifySlotAs().
            ///
            /// Panics on failure.
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
