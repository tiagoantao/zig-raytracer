const std = @import("std");
const Allocator = std.mem.Allocator;
const pow = std.math.pow;


pub fn Vector(comptime T: type) type {
    return struct {
        x: T,
        y: T,
        z: T,

        pub fn init(x: T, y: T, z: T) @This() {
            return @This() { .x = x, .y = y, .z = z };
        }

        pub fn sum(a: @This(), b: @This()) @This() {
            return @This(){.x=a.x + b.x, .y=a.y + b.y, .z=a.z + b.z};
        }

        pub fn sub(a: @This(), b: @This()) @This() {
            return @This(){.x=a.x - b.x, .y=a.y - b.y, .z=a.z - b.z};
        }

        pub fn dot(a: @This(), b: @This()) T {
            return a.x * b.x + a.y * b.y + a.z * b.z;
        }

        pub fn mult_num(comptime V:type, a: V, b: @This()) @This() {
            return @This(){.x = a * b.x, .y = a * b.y, .z = a * b.z};
        }

        pub fn length(a: @This()) T {
            return pow(T, a.x, 2) + pow(T, a.y, 2) + pow(T, a.z, 2);
        }

        pub fn unit_vector(a: @This()) @This() {
            return @This(){.x = a.x / a.length(), .y = a.y / a.length(), .z = a.z / a.length()};
        }
    };
}
