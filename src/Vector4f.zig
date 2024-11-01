const std = @import("std");

x: f32,
y: f32,
z: f32,
w: f32,

const Self = @This();

pub fn init(x: f32, y: f32, z: f32, w: f32) Self {
	return Self{ .x = x, .y = y, .z=z, .w=w};
}

pub fn init3D(x: f32, y: f32, z: f32) Self {
	return Self.init(x, y, z, 1.0);
}

pub fn length(self: Self) f32 {
	return @sqrt(self.x * self.x + self.y * self.y + self.z * self.z + self.w * self.w);
}

pub fn max(self: Self) f32 {
	return std.math.max(f32, std.math.max(f32, self.x, self.y), std.math.max(f32, self.z, self.w));
}

pub fn dot(self: Self, r: Self) f32 {
	return self.x * r.x + self.y * r.y + self.z * r.z + self.w * r.w;
}

pub fn cross(self: Self, r: Self) Self {
	return Self.init(
		self.y * r.z - self.z * r.y,
		self.z * r.x - self.x * r.z,
		self.x * r.y - self.y * r.x,
		0.0,
	);
}

pub fn normalized(self: Self) Self {
	const l = self.length();
	return Self.init(self.x / l, self.y / l, self.z / l, self.w / l);
}

pub fn rotate(self: Self, axis: Self, angle: f32) Self {
	const sinAngle = std.math.sin(-angle);
	const cosAngle = std.math.cos(-angle);

	return self.cross(axis.mul(sinAngle)).add(
		self.mul(cosAngle).add(axis.mul(self.dot(axis.mul(1 - cosAngle))))
	);
}

pub fn lerp(self: Self, dest: Self, lerpFactor: f32) Self {
	return dest.sub(self).mul(lerpFactor).add(self);
}

pub fn add(self: Self, r: Self) Self {
	return Self.init(self.x + r.x, self.y + r.y, self.z + r.z, self.w + r.w);
}

pub fn addScalar(self: Self, r: f32) Self {
	return Self.init(self.x + r, self.y + r, self.z + r, self.w + r);
}

pub fn sub(self: Self, r: Self) Self {
	return Self.init(self.x - r.x, self.y - r.y, self.z - r.z, self.w - r.w);
}

pub fn subScalar(self: Self, r: f32) Self {
	return Self.init(self.x - r, self.y - r, self.z - r, self.w - r);
}

pub fn mul(self: Self, r: Self) Self {
	return Self.init(self.x * r.x, self.y * r.y, self.z * r.z, self.w * r.w);
}

pub fn mulScalar(self: Self, r: f32) Self {
	return Self.init(self.x * r, self.y * r, self.z * r, self.w * r);
}

pub fn div(self: Self, r: Self) Self {
	return Self.init(self.x / r.x, self.y / r.y, self.z / r.z, self.w / r.w);
}

pub fn divScalar(self: Self, r: f32) Self {
	return Self.init(self.x / r, self.y / r, self.z / r, self.w / r);
}

pub fn abs(self: Self) Self {
	return Self.init(
		std.math.abs(self.x),
		std.math.abs(self.y),
		std.math.abs(self.z),
		std.math.abs(self.w)
	);
}

pub fn toString(self: Self) []const u8 {
	return std.fmt.allocPrint(std.heap.page_allocator, "({}, {}, {}, {})", .{self.x, self.y, self.z, self.w}) catch "Error";
}

pub fn equals(self: Self, r: Self) bool {
	return self.x == r.x and self.y == r.y and self.z == r.z and self.w == r.w;
}

pub fn triangleArea(self: *const Self, b: *const Self, c: *const Self) f32 {
    return 0.5 * (self.x * (b.y - c.y) + b.x * (c.y - self.y) + c.x * (self.y - b.y));
}

pub fn perspectiveDivide(self: *const Self) Self {
	return Self.init(
		self.x / self.w,
		self.y / self.w,
		self.z / self.w,
		self.w );
}