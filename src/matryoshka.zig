// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! matryoshka-io: infrastructure for std.Io-based concurrent Zig code.
//!
//! Three building blocks, one rule: an object sits in exactly one place,
//! in exactly one state, at any moment.
//! - polynode: runtime type identity for intrusive list nodes.
//! - mailbox: sends objects between execution contexts.
//! - pool: lifecycle management with user-supplied hooks.

pub const polynode = @import("polynode.zig");
pub const mailbox = @import("mailbox.zig");
pub const pool = @import("pool.zig");

const std = @import("std");
