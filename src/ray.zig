const std = @import("std");
const Allocator = std.mem.Allocator;
const pow = std.math.pow;
const Vector = @import("vector.zig").Vector;

pub fn Ray(comptime T: type) type {
    return struct {
        origin: Vector(T),
        direction: Vector(T),

        pub fn point_at_parameter(comptime V: type, r: @This(), t: V) Vector(T) {
            return Vector(T).sum(r.origin, Vector(T).mult_num(V, t, r.direction));
        }
    };
}

