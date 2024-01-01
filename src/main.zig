const std = @import("std");
const Allocator = std.mem.Allocator;
const pow = std.math.pow;


pub fn Vector3D(comptime T: type) type {
    return [3]T;
}

pub fn Ray(comptime T: type) type {
    return struct {
         origin: Vector3D(T),
         direction: Vector3D(T)
    };
}


pub fn vec_sum(comptime T: type, a: Vector3D(T), b: Vector3D(T)) Vector3D(T) {
    return .{a[0] + b[0], a[1] + b[1], a[2] + b[2]};
}


pub fn vec_sub(comptime T: type, a: Vector3D(T), b: Vector3D(T)) Vector3D(T) {
    return .{a[0] - b[0], a[1] - b[1], a[2] - b[2]};
}

pub fn vec_dot(comptime T: type, a: Vector3D(T), b: Vector3D(T)) T {
    return a[0] * b[0] + a[1] * b[1] + a[2] * b[2];
}


pub fn mult_num_vector(comptime T: type, comptime V: type, a: T , b: Vector3D(V)) Vector3D(V) {
    return .{a * b[0], a * b[1], a * b[2]};
}


pub fn point_at_parameter(comptime T: type, comptime V: type, r: Ray(T), t: V) Vector3D(T) {
    return vec_sum(T, r.origin, mult_num_vector(V, T, t, r.direction));
}


// color for Blue gradient
pub fn color_blue(comptime T: type, r: Ray(T)) Vector3D(T) {
    const norm = @sqrt(pow(T, r.direction[0], 2) + pow(T, r.direction[1], 2) + pow(T, r.direction[2], 2));
    const unit_direction: Vector3D = .{
        r.direction[0] / norm,
        r.direction[1] / norm,
        r.direction[2] / norm};
    const t = 0.5 * (unit_direction[1] + 1.0);
    return vec_sum(T,
        mult_num_vector(f32, T, (1.0 - t), .{1.0, 1.0, 1.0}),
        mult_num_vector(f32, T, t, .{0.5, 0.7, 1.0}));
}


pub fn hit_sphere(comptime T: type, center: Vector3D(T), radius: f32, r: Ray(T)) f32 {
    const oc = vec_sub(T, r.origin, center);
    const a = vec_dot(T, r.direction, r.direction);
    const b = 2.0 * vec_dot(T, oc, r.direction);
    const c = vec_dot(T, oc, oc) - radius * radius;
    const discriminant = b * b - 4.0 * a * c;
    if (discriminant < 0.0) {
        return -1.0;
    } else {
        return (-b - @sqrt(discriminant)) / (2.0 * a);
    }
}


pub fn color_sphere(comptime T: type, r: Ray(T)) Vector3D(T) {
    const t: f32 = hit_sphere(T, .{0.0, 0.0, -1.0}, 0.5, r);
    if (t > 0.0) {
        const N = vec_sub(T, point_at_parameter(T, f32, r, t), .{0.0, 0.0, -1.0});
        return mult_num_vector(f32, T, 0.5, .{N[0] + 1.0, N[1] + 1.0, N[2] + 1.0});
    }
    const norm = @sqrt(pow(f32, r.direction[0], 2) + pow(f32, r.direction[1], 2) + pow(f32, r.direction[2], 2));
    const unit_direction: Vector3D(T) = .{
        r.direction[0] / norm,
        r.direction[1] / norm,
        r.direction[2] / norm};
    const t2 = 0.5 * (unit_direction[1] + 1.0);
    return vec_sum(T,
        mult_num_vector(f32, T, (1.0 - t2), .{1.0, 1.0, 1.0}),
        mult_num_vector(f32, T, t2, .{0.5, 0.7, 1.0}));
}


pub fn RayFn(comptime T: type) type {
    return fn(T: type, Ray(T)) Vector3D(T);
}


pub fn color_objects(comptime T: type, objects: [] const RayFn(T), r: Ray(T)) ?Vector3D(T) {
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
    const lower_left_corner = .{-2.0, -1.0, -1.0};
    const horizontal = .{4.0, 0.0, 0.0};
    const vertical = .{0.0, 2.0, 0.0};
    for (0..height) |j| {
        for (0..width) |i| {
            const u: f32 = @as(T, @floatFromInt(i)) / @as(T, @floatFromInt(width));
            const v: f32 = @as(T, @floatFromInt(j)) / @as(T, @floatFromInt(height));
            const r = Ray(T) {
                .origin = .{0.0, 0.0, 0.0},
                .direction = vec_sum(T, lower_left_corner,
                    vec_sum(f32,
                        mult_num_vector(T, T, u, horizontal),
                        mult_num_vector(T, T, v, vertical)))};
            //const col = color_sphere(T, r);
            const col = color_fun(T, r);
            const ir: u8 = @intFromFloat(255.99*col[0]);
            const ig: u8 = @intFromFloat(255.99*col[1]);
            const ib: u8 = @intFromFloat(255.99*col[2]);
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
