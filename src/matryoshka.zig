// SPDX-FileCopyrightText: Copyright (c) 2026 g41797
// SPDX-License-Identifier: MIT

//! Building blocks for concurrent Zig systems.
//!
//! Components:
//! - polynode: runtime type support
//! - mailbox: message passing
//! - pool: item lifecycle management
//!

pub const polynode = @import("polynode.zig");
pub const mailbox = @import("mailbox.zig");
pub const pool = @import("pool.zig");

const std = @import("std");
