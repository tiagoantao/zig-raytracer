const std = @import("std");
const Allocator = std.mem.Allocator;
const pow = std.math.pow;
const Vector = @import("vector.zig").Vector;
const ray = @import("ray.zig");
const img = @import("image.zig");

const Vec = Vector(f32);
const Ray = ray.Ray(f32);


// color for Blue gradient
pub fn color_blue(comptime T: type, r: Ray) Vec {
    const norm = @sqrt(pow(T, r.direction[0], 2) + pow(T, r.direction[1], 2) + pow(T, r.direction[2], 2));
    const unit_direction: Vector = .{
        r.direction[0] / norm,
        r.direction[1] / norm,
        r.direction[2] / norm};
    const t = 0.5 * (unit_direction[1] + 1.0);
    return Vec.sum(
        Vec.mult_num(T, (1.0 - t), Vec(1.0, 1.0, 1.0)),
        Vec.mult_num(T, t, Vec(0.5, 0.7, 1.0)));
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


pub fn color_sphere(comptime T: type, r: Ray) Vec {
    const t: f32 = hit_sphere(Vec.init(0.0, 0.0, -1.0), 0.5, r);
    if (t > 0.0) {
        const N = Vec.sub(Ray.point_at_parameter(f32, r, t), Vec.init(0.0, 0.0, -1.0));
        return Vec.mult_num(
            T, 0.5,
            Vec.init(N.x + 1.0, N.y + 1.0, N.z + 1.0));
    }
    const norm = @sqrt(pow(f32, r.direction.x, 2) + pow(f32, r.direction.y, 2) + pow(f32, r.direction.z, 2));
    const unit_direction: Vec = Vec.init(
        r.direction.x / norm,
        r.direction.y / norm,
        r.direction.z / norm);
    const t2 = 0.5 * (unit_direction.y + 1.0);
    return Vec.sum(
        Vec.mult_num(f32, (1.0 - t2), Vec.init(1.0, 1.0, 1.0)),
        Vec.mult_num(f32, t2, Vec.init(0.5, 0.7, 1.0)));
}


pub fn RayFn() type {
    return fn(Ray) Vec;
}


//pub fn color_objects(comptime T: type, objects: [] const RayFn, r: Ray) ?Vec {
//    return .{0.0, 0.0, 0.0};
//}


pub fn generate_from_ray(comptime T: type, allocator: Allocator, color_fun: RayFn(T), width: u16, height: u16) ![][][3] u8 {
    var image: [][][3] u8 = try img.allocate_image(allocator, width, height);
    const lower_left_corner = Vec.init(-2.0, -1.0, -1.0);
    const horizontal = Vec.init(4.0, 0.0, 0.0);
    const vertical = Vec.init(0.0, 2.0, 0.0);
    for (0..height) |j| {
        for (0..width) |i| {
            const u: f32 = @as(T, @floatFromInt(i)) / @as(T, @floatFromInt(width));
            const v: f32 = @as(T, @floatFromInt(j)) / @as(T, @floatFromInt(height));
            const r = Ray {
                .origin = Vec.init(0.0, 0.0, 0.0),
                .direction = Vec.sum(lower_left_corner,
                    Vec.sum(
                        Vec.mult_num(T, u, horizontal),
                        Vec.mult_num(T, v, vertical)))};
            //const col = color_sphere(T, r);
            const col = color_fun(T, r);
            const ir: u8 = @intFromFloat(255.99*col.x);
            const ig: u8 = @intFromFloat(255.99*col.y);
            const ib: u8 = @intFromFloat(255.99*col.z);
            image[j][i] = .{ir, ig, ib};
        }
    }
    return image;
}


pub fn main() !void {
    //const image = try generate_gradient_image(std.heap.page_allocator, 640, 480);
    const image = try generate_from_ray(f32, std.heap.page_allocator, color_sphere, 640, 480);
    try img.write_pnm("out.pnm", image);
}
