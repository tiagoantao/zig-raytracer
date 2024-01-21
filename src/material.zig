const std = @import("std");
const Vector = @import("vector.zig").Vector;

const Vec = Vector(f32);

pub fn random_in_unit_sphere(comptime T: type) Vec {
    var p: Vec = undefined;
    var rng = std.rand.DefaultPrng.init(0); // seed with 0 - bad idea
    while (true) {
        p = Vec.mult_num(T, 2.0,
            Vec.sub(
                Vec{.x=rng.random().float(f32), .y=rng.random().float(f32), .z=rng.random().float(f32)},
                Vec{.x=1, .y=1, .z=1}));
        if (p.length_squared() < 1.0) {
            break;
        }
    }
    return p;
}
