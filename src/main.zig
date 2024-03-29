const std = @import("std");
const ArrayList = std.ArrayList;
const Allocator = std.mem.Allocator;
const pow = std.math.pow;
const sqrt = std.math.sqrt;
const Vector = @import("vector.zig").Vector;
const ray = @import("ray.zig");
const img = @import("image.zig");
const hit = @import("hit.zig");
const material = @import("material.zig");
const Camera = @import("camera.zig").Camera;

const Vec = Vector(f32);
const Ray = ray.Ray(f32);
const max_f32_float: f32 = std.math.floatMax(f32);

// color for Blue gradient
pub fn color_blue(comptime T: type, r: Ray) Vec {
    const norm = @sqrt(pow(T, r.direction[0], 2) + pow(T, r.direction[1], 2) + pow(T, r.direction[2], 2));
    const unit_direction: Vector = .{ r.direction[0] / norm, r.direction[1] / norm, r.direction[2] / norm };
    const t = 0.5 * (unit_direction[1] + 1.0);
    return Vec.sum(Vec.mult_num(T, (1.0 - t), Vec(1.0, 1.0, 1.0)), Vec.mult_num(T, t, Vec(0.5, 0.7, 1.0)));
}

pub fn hit_sphere(center: Vec, radius: f32, r: Ray) f32 {
    const oc = Vec.sub(r.origin, center);
    const a = Vec.dot(r.direction, r.direction);
    const b = 2.0 * Vec.dot(oc, r.direction);
    const c = Vec.dot(oc, oc) - radius * radius;
    const discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) {
        return -1.0;
    } else {
        return (-b - @sqrt(discriminant)) / (2.0 * a);
    }
}


pub fn color_sphere(r: Ray) Vec {
    const t: f32 = hit_sphere(Vec.init(0.0, 0.0, -1.0), 0.5, r);
    if (t > 0.0) {
        const N = Vec.sub(Ray.point_at_parameter(f32, r, t), Vec.init(0.0, 0.0, -1.0));
        return Vec.mult_num(f32, 0.5, Vec.init(N.x + 1.0, N.y + 1.0, N.z + 1.0));
    }
    const norm = @sqrt(pow(f32, r.direction.x, 2) + pow(f32, r.direction.y, 2) + pow(f32, r.direction.z, 2));
    const unit_direction: Vec = Vec.init(r.direction.x / norm, r.direction.y / norm, r.direction.z / norm);
    const t2 = 0.5 * (unit_direction.y + 1.0);
    return Vec.sum(Vec.mult_num(f32, (1.0 - t2), Vec.init(1.0, 1.0, 1.0)), Vec.mult_num(f32, t2, Vec.init(0.5, 0.7, 1.0)));
}


pub fn color_list(r: Ray, list: hit.List) Vec {
    const my_hit: ?hit.Hit = hit.hit_list(list, r, 0.001, max_f32_float);
    if (my_hit) |ohit| {
        const target: Vec = Vec.sum(
            ohit.p,
            Vec.sum(ohit.normal, material.random_in_unit_sphere(f32)));
        return Vec.mult_num(f32, 0.5, 
            color_list(Ray { .origin = ohit.p, .direction = Vec.sub(target, ohit.p) }, list));
        //return Vec.mult_num(f32, 0.5, Vec.init(ohit.normal.x + 1.0, ohit.normal.y + 1.0, ohit.normal.z + 1.0));
    } else {
        const unit_direction = Vec.unit_vector(r.direction);
        const t = 0.5 * (unit_direction.y + 1.0);
        return Vec.sum(
            Vec.mult_num(f32,
                (1.0 - t),
                Vec.init(1.0, 1.0, 1.0)),
            Vec.mult_num(f32, t, Vec.init(0.5, 0.7, 1.0)));
    }
}

pub fn color_world(r: Ray, world: hit.Object) Vec {
    const color = switch (world) {
        hit.ObjectEnum.list => color_list(r, world.list),
        else => unreachable,
    };
    return color;
}

pub fn RayFn() type {
    return fn (Ray, hit.Object) Vec;
}


pub fn generate_from_ray(comptime T: type, allocator: Allocator, comptime color_fun: RayFn(), world: hit.Object, width: u16, height: u16) ![][][3]u8 {
    var image: [][][3]u8 = try img.allocate_image(allocator, width, height);
    const origin = Vec.init(0.0, 0.0, 0.0);
    const lower_left_corner = Vec.init(-2.0, -1.0, -1.0);
    const horizontal = Vec.init(4.0, 0.0, 0.0);
    const vertical = Vec.init(0.0, 2.0, 0.0);
    const camera = Camera(T).init(origin, lower_left_corner, horizontal, vertical);
    const reps: f32 = 100;
    var rng = std.rand.DefaultPrng.init(0); // Should not be 0 - deterministic
    for (0..height) |j| {
        for (0..width) |i| {
            //const col = color_sphere(T, r);
            var col: Vec = Vec.init(0.0, 0.0, 0.0);
            for (0..reps) |_| {
                const u: f32 = (@as(T, @floatFromInt(i)) + rng.random().float(T)) / @as(T, @floatFromInt(width));
                const v: f32 = (@as(T, @floatFromInt(j)) + rng.random().float(T)) / @as(T, @floatFromInt(height));
                const r = camera.get_ray(u, v);
                col = Vec.sum(col, color_fun(r, world));
            }
            col = Vec.div_num(f32, reps, col);
            col = Vec.init(@sqrt(col.x), @sqrt(col.y), @sqrt(col.z));
            const ir: u8 = @intFromFloat(255.99 * col.x);
            const ig: u8 = @intFromFloat(255.99 * col.y);
            const ib: u8 = @intFromFloat(255.99 * col.z);
            image[height - (j + 1)][i] = .{ ir, ig, ib };
        }
    }
    return image;
}

//pub fn main() !void {
//    //const image = try generate_gradient_image(std.heap.page_allocator, 640, 480);
//    const image = try generate_from_ray(f32, std.heap.page_allocator, color_sphere, 640, 480);
//    try img.write_pnm("out.pnm", image);
//}
//
//

pub fn my_world(allocator: Allocator) !hit.Object {
    var list = ArrayList(hit.Object).init(allocator);
    //defer list.deinit();
    const s1 = hit.Sphere{ .center = Vec.init(0.0, 0.0, -1.0), .radius = 0.5 };
    const s2 = hit.Sphere{ .center = Vec.init(0.0, -100.5, -1.0), .radius = 100.0 };
    try list.append(hit.Object{ .sphere = s1 });
    try list.append(hit.Object{ .sphere = s2 });
    return hit.Object{ .list = list };
}

pub fn main() !void {
    const allocator = std.heap.page_allocator;
    const world = try my_world(allocator);
    const image = try generate_from_ray(f32, std.heap.page_allocator, color_world, world, 640, 480);
    try img.write_pnm("out.pnm", image);
}
