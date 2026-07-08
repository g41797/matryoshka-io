//! Just a demo item — not for production.
poly: polynode.PolyNode = .{},

pub const ShutdownCommandPolyHelper = polynode.PolyHelper(Self);

const Self = @This();
const polynode = @import("matryoshka").polynode;
