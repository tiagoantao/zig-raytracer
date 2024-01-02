const std = @import("std");
const Allocator = std.mem.Allocator;
const pow = std.math.pow;


pub fn Vector3D(comptime T: type) type {
    const Vector = struct {
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
    };
    return Vector;
}
