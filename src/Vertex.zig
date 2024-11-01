const std = @import("std");
pub const Vector4f = @import("Vector4f.zig");
pub const Matrix4f = @import("Matrix4f.zig");

const Self = @This();

position : Vector4f = undefined,

// pub fn x(self: Self) f32 {
//     return self.position.x;
// }

// pub fn y(self: Self) f32 {
//     return self.position.y;
// }

// pub fn init(pos_x: f32, pos_y: f32) Self {
//     return Self{ .position = Vector4f.init( pos_x, pos_y , 0 , 1) };
// }

pub fn initFromVector4f( pos: *const Vector4f) Self {
    return Self{ .position = pos.* };
}

pub fn transform( self : *Self, mat : *const Matrix4f) Self {
    const position = mat.transform(self.position);
    return Self{ .position = position };
}

pub fn triangleArea(self: *const Self, b: *const Self, c: *const Self) f32 {
    return 0.5 * (self.x() * (b.y() - c.y()) + b.x() * (c.y() - self.y()) + c.x() * (self.y() - b.y()));
}


