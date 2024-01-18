const Vector = @import("vector.zig").Vector;
const Ray = @import("ray.zig").Ray;


pub fn Camera(comptime T: type) type {
   return struct {
       origin: Vector(T),
       lower_left_corner: Vector(T),
       horizontal: Vector(T),
       vertical: Vector(T),

       pub fn init(
           origin: Vector(T),
           lower_left_corner: Vector(T),
           horizontal: Vector(T),
           vertical: Vector(T)) @This() {
        return @This() {
            .origin = origin,
            .lower_left_corner = lower_left_corner,
            .horizontal = horizontal, 
            .vertical = vertical};
       }


       pub fn get_ray(me: @This(), u:T, v: T) Ray(T) {
           const r = Ray(T) {
               .origin = Vector(T).init(0.0, 0.0, 0.0),
               .direction = Vector(T).sum(
                   me.lower_left_corner,
                   Vector(T).sum(
                       Vector(T).mult_num(T, u, me.horizontal),
                       Vector(T).mult_num(T, v, me.vertical)))
            };
            return r;
       }
   };
}
