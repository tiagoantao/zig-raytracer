const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const pow = std.math.pow;
const Vector = @import("vector.zig").Vector;
const ray = @import("ray.zig");
const img = @import("image.zig");

const Vec = Vector(f32);
const Ray = ray.Ray(f32);

pub const Hit = struct {t: f32, p: Vec, normal: Vec };

pub const Sphere = struct {center: Vec, radius: f32};

pub const List = ArrayList(Object);

pub const ObjectEnum = enum {
    list,
    sphere
};
pub const Object = union(ObjectEnum) {
    list: List,
    sphere: Sphere,
};


pub fn hit_sphere(s: Sphere, r: Ray, t_min: f32, t_max: f32) ?Hit {
    const oc = Vec.sub(r.origin, s.center);
    const a = Vec.dot(r.direction, r.direction);
    const b = Vec.dot(oc, r.direction);
    const c = Vec.dot(oc, oc) - s.radius * s.radius;
    const discriminant = b * b - a * c;
    if (discriminant > 0.0) {
        const temp = (-b - @sqrt(discriminant)) / a;
        if (temp < t_max and temp > t_min) {
            const p = Ray.point_at_parameter(f32, r, temp);
            const normal = Vec.mult_num(f32, 1.0 / s.radius, Vec.sub(p, s.center));
            return .{.t=temp, .p=p, .normal=normal};
        }
    }
    else {
        const temp = (-b + @sqrt(discriminant)) / a;
        if (temp < t_max and temp > t_min) {
            const p = Ray.point_at_parameter(f32, r, temp);
            const normal = Vec.mult_num(f32, 1.0 / s.radius, Vec.sub(p, s.center));
            return .{.t=temp, .p=p, .normal=normal};
        }
    }
    return null;
}


pub fn hit_list(l: List, r: Ray, t_min: f32, t_max: f32) ?Hit {
    var closest_so_far: f32 = t_max;
    var temp_hit: ?Hit = null;
    for (l.items) |obj| {
        const hit = switch (obj) {
            ObjectEnum.sphere => hit_sphere(obj.sphere, r, t_min, closest_so_far),
            ObjectEnum.list => unreachable
        };
        if (hit) |value| {
            closest_so_far = value.t;
            temp_hit = hit;
        }
    }
    return temp_hit;
}
