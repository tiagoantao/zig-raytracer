const std = @import("std");
const Allocator = std.mem.Allocator;

const vector_3d = [3]f32;

const Ray = struct {
    origin: vector_3d,
    direction: vector_3d,
};


pub fn vec_sum(a: vector_3d, b: vector_3d) vector_3d {
    return .{a[0] + b[0], a[1] + b[1], a[2] + b[2]};
}


pub fn mult_num_vector(comptime T: type, a: T , b: vector_3d) vector_3d {
    return .{a * b[0], a * b[1], a * b[2]};
}


pub fn point_at_parameter(r: Ray, t: f32) vector_3d {
    return r.origin + t * r.direction;
}


pub fn color(r: Ray) [3]f32 {
    const unit_direction = r.direction / @sqrt(r.direction[0]**2 + r.direction[1]**2 + r.direction[2]**2);
    const t = 0.5 * (unit_direction[1] + 1.0);
    return (1.0 - t) * .{1.0, 1.0, 1.0} + t * .{0.5, 0.7, 1.0};
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


pub fn generate_blue_gradient(allocator: Allocator, width: u16, height: u16) ![][][3] u8 {
    var image: [][][3] u8 = try allocate_image(allocator, width, height);
    const lower_left_corner = .{-2.0, -1.0, -1.0};
    const horizontal = .{4.0, 0.0, 0.0};
    const vertical = .{0.0, 2.0, 0.0};
    for (0..height) |j| {
        for (0..width) |i| {
            const u: f32 = @as(f32, @floatFromInt(i)) / @as(f32, @floatFromInt(width));
            const v: f32 = @as(f32, @floatFromInt(j)) / @as(f32, @floatFromInt(height));
            const r = Ray {
                .origin = .{0.0, 0.0, 0.0},
                .direction = vec_sum(lower_left_corner,
                    vec_sum(
                        mult_num_vector(f32, u, horizontal),
                        mult_num_vector(f32, v, vertical)))};
            const col = color(r);
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
    const image = try generate_blue_gradient(std.heap.page_allocator, 640, 480);
    try write_pnm("out.pnm", image);
}
