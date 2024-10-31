const std = @import("std");

const Self = @This();

x: f32 = undefined,
y: f32 = undefined,

pub fn init(x: f32, y: f32) Self {
    return Self{ .x = x, .y = y };
}

pub fn triangleArea(self: *const Self, b: *const Self, c: *const Self) f32 {
    return 0.5 * (self.x * (b.y - c.y) + b.x * (c.y - self.y) + c.x * (self.y - b.y));
}


