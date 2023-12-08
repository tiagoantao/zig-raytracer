const std = @import("std");
const Allocator = std.mem.Allocator;

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

pub fn main() !void {
    const image = try generate_gradient_image(std.heap.page_allocator, 640, 480);
    try write_pnm("out.pnm", image);
}
