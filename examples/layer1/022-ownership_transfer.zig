// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Ownership transfer via Slot.
//!
//! - Create an Event, wrap it in a Slot.
//! - Transfer the Slot into a list, clear the Slot.
//! - Pop the item back out of the list, assign it to a Slot.
//! - Verify the recovered data, then free it.
//!
//!
//! ```
//!  alloc.create ──► slot (non-null)
//!       │ list.append + slot=null
//!       ▼
//!  list (owns item)
//!       │ list.popFirst + slot=item
//!       ▼
//!  slot (owns item again)
//!       │ freeSlot
//!       ▼
//!  freed
//! ```
//!

pub fn ownership_transfer_via_slot(allocator: std.mem.Allocator, io: std.Io) !void {
    _ = io;

    var slot: Slot = null;
    defer types.EventPolyHelper.destroy(allocator, &slot);
    try types.EventPolyHelper.create(allocator, &slot);
    const ev: *types.Event = types.EventPolyHelper.mustIdentifySlotAs(&slot);
    ev.*.code = 42;
    try helpers.expect(error.OwnershipTransferFailed, slot != null, "slot should be non-null after create");

    // Transfer to list — clear slot to signal transfer.
    var list: std.DoublyLinkedList = .{};
    list.append(&slot.?.node);
    slot = null;
    try helpers.expect(error.OwnershipTransferFailed, slot == null, "slot should be null after transfer");

    // Recover from list — assign back to slot.
    const node: *std.DoublyLinkedList.Node = list.popFirst() orelse return error.EmptyList;
    slot = @fieldParentPtr("node", node);
    try helpers.expect(error.OwnershipTransferFailed, slot != null, "slot should be non-null after recovery");

    const recovered: *types.Event = types.EventPolyHelper.mustIdentifySlotAs(&slot);
    try helpers.expect(error.OwnershipTransferFailed, recovered.*.code == 42, "wrong event code");

    helpers.freeSlot(&slot, allocator);
    try helpers.expect(error.OwnershipTransferFailed, slot == null, "slot should be null after destroy");
    // defer runs as no-op
}

const helpers = @import("helpers");
const polynode = @import("matryoshka").polynode;
const std = @import("std");
const Slot = polynode.Slot;
const types = helpers.types;
