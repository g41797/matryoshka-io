//! Just a demo item — not for production.
poly: polynode.PolyNode = .{},

pub const TimerPolyHelper = polynode.PolyHelper(Self);

const Self = @This();
const polynode = @import("matryoshka").polynode;
