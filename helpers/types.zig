pub const Event = struct {
    poly: polynode.PolyNode = .{},
    code: i32 = 0,
};

pub const Sensor = struct {
    poly: polynode.PolyNode = .{},
    value: f64 = 0.0,
};

pub const ShutdownCommand = struct {
    poly: polynode.PolyNode = .{},
};

pub const EventPolyHelper = polynode.PolyHelper(Event);
pub const SensorPolyHelper = polynode.PolyHelper(Sensor);
pub const ShutdownCommandPolyHelper = polynode.PolyHelper(ShutdownCommand);

const polynode = @import("matryoshka").polynode;
