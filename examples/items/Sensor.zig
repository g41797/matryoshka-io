//! Just a demo item — not for production.
poly: polynode.PolyNode = .{},
value: f64 = 0.0,

pub const SensorPolyHelper = polynode.PolyHelper(Self);

const Self = @This();
const polynode = @import("matryoshka").polynode;
