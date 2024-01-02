const std = @import("std");
const Allocator = std.mem.Allocator;
const pow = std.math.pow;
const Vector = @import("vector.zig").Vector3D;


pub fn Ray(comptime T: type) type {
    return struct {
         origin: Vector(T),
         direction: Vector(T)
    };
}


pub fn point_at_parameter(comptime T: type, comptime V: type, r: Ray(T), t: V) Vector(T) {
    return Vector(T).sum(r.origin, Vector(T).mult_num(V, t, r.direction));
}


// color for Blue gradient
pub fn color_blue(comptime T: type, r: Ray(T)) Vector(T) {
    const norm = @sqrt(pow(T, r.direction[0], 2) + pow(T, r.direction[1], 2) + pow(T, r.direction[2], 2));
    const unit_direction: Vector = .{
        r.direction[0] / norm,
        r.direction[1] / norm,
        r.direction[2] / norm};
    const t = 0.5 * (unit_direction[1] + 1.0);
    return Vector(T).sum(
        Vector(T).mult_num(T, (1.0 - t), Vector(T)(1.0, 1.0, 1.0)),
        Vector(T).mult_num(T, t, Vector(T)(0.5, 0.7, 1.0)));
}


pub fn hit_sphere(comptime T: type, center: Vector(T), radius: f32, r: Ray(T)) f32 {
    const oc = Vector(T).sub(r.origin, center);
    const a = Vector(T).dot(r.direction, r.direction);
    const b = 2.0 * Vector(T).dot(oc, r.direction);
    const c = Vector(T).dot(oc, oc) - radius * radius;
    const discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) {
        return -1.0;
    } else {
        return (-b - @sqrt(discriminant)) / (2.0 * a);
    }
}


pub fn color_sphere(comptime T: type, r: Ray(T)) Vector(T) {
    const t: f32 = hit_sphere(T, Vector(T).init(0.0, 0.0, -1.0), 0.5, r);
    if (t > 0.0) {
        const N = Vector(T).sub(point_at_parameter(T, f32, r, t), Vector(T).init(0.0, 0.0, -1.0));
        return Vector(T).mult_num(
            T, 0.5,
            Vector(T).init(N.x + 1.0, N.y + 1.0, N.z + 1.0));
    }
    const norm = @sqrt(pow(f32, r.direction.x, 2) + pow(f32, r.direction.y, 2) + pow(f32, r.direction.z, 2));
    const unit_direction: Vector(T) = Vector(T).init(
        r.direction.x / norm,
        r.direction.y / norm,
        r.direction.z / norm);
    const t2 = 0.5 * (unit_direction.y + 1.0);
    return Vector(T).sum(
        Vector(T).mult_num(f32, (1.0 - t2), Vector(T).init(1.0, 1.0, 1.0)),
        Vector(T).mult_num(f32, t2, Vector(T).init(0.5, 0.7, 1.0)));
}


pub fn RayFn(comptime T: type) type {
    return fn(T: type, Ray(T)) Vector(T);
}


pub fn color_objects(comptime T: type, objects: [] const RayFn(T), r: Ray(T)) ?Vector(T) {
    _ = r;
    _ = objects;
    return .{0.0, 0.0, 0.0};
}


pub fn write_pnm(fname: []const u8, image: [][][3] u8) !void {
    var file = try std.fs.cwd().createFile(fname, .{});
    defer file.close();
    var writer = file.writer(); 
    const height = image.len;
    const width = image[0].len;
    try writer.print("P3\n{d} {d}\n255\n", .{width, height});
    for (0..height) |j| {
        for (0..width) |i| {
            const r = image[j][i][0];
            const g = image[j][i][1];
            const b = image[j][i][2];
            try writer.print("{d} {d} {d}\n", .{r, g, b});
        }
    }
}


pub fn allocate_image(allocator: Allocator, width: u16, height: u16) ![][][3] u8 {
    const image: [][][3]u8 = try allocator.alloc([][3]u8, height);
    for (0..height) |j| {
        image[j] = try allocator.alloc([3]u8, width);
    }
    return image;
}


pub fn generate_gradient_image(allocator: Allocator, width: u16, height: u16) ![][][3] u8 {
    var image: [][][3] u8 = try allocate_image(allocator, width, height);
    for (0..height) |j| {
        for (0..width) |i| {
            const r: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(width));
            const g: f32 = @as(f32, @floatFromInt(j)) / @as(f32, @floatFromInt(height));
            const b: f32 = 0.2;
            const ir: u8 = @intFromFloat(r * 255.0);
            const ig: u8 = @intFromFloat(g * 255.0);
            const ib: u8 = @intFromFloat(b * 255.0);
            image[j][i] = .{ir, ig, ib};
        }
    }
    return image;
}


pub fn generate_from_function(comptime T: type, allocator: Allocator, color_fun: RayFn(T), width: u16, height: u16) ![][][3] u8 {
    var image: [][][3] u8 = try allocate_image(allocator, width, height);
    const lower_left_corner = Vector(T).init(-2.0, -1.0, -1.0);
    const horizontal = Vector(T).init(4.0, 0.0, 0.0);
    const vertical = Vector(T).init(0.0, 2.0, 0.0);
    for (0..height) |j| {
        for (0..width) |i| {
            const u: f32 = @as(T, @floatFromInt(i)) / @as(T, @floatFromInt(width));
            const v: f32 = @as(T, @floatFromInt(j)) / @as(T, @floatFromInt(height));
            const r = Ray(T) {
                .origin = Vector(T).init(0.0, 0.0, 0.0),
                .direction = Vector(T).sum(lower_left_corner,
                    Vector(T).sum(
                        Vector(T).mult_num(T, u, horizontal),
                        Vector(T).mult_num(T, v, vertical)))};
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
    const image = try generate_from_function(f32, std.heap.page_allocator, color_sphere, 640, 480);
    try write_pnm("out.pnm", image);
}
