const std = @import("std");
const Vector4f = @import("Vector4f.zig");

const Self = @This();

m: [4][4]f32,

pub fn init() Self {
    return Self.createIdentity();
}

pub fn createIdentity() Self {
    return Self { .m =  .{
        .{ 1, 0, 0, 0 },
        .{ 0, 1, 0, 0 },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    }};
}

pub fn createScreenTransform( half_width: f32, half_height: f32) Self {
    return Self { .m =  .{
        .{ half_width, 0, 0, half_width  },
        .{ 0, -half_height, 0, half_height },
        .{ 0, 0, 1, 0 },
        .{ 0, 0, 0, 1 },
    }};
}

pub fn createPerspective( fov : f32, aspectRatio : f32, z_near : f32, z_far : f32) Self {
    const tanHalfFOV = std.math.tan(fov / 2.0);
    const zRange = z_near - z_far;

    return Self{ .m =  .{
        .{ 1 / (tanHalfFOV * aspectRatio), 0             , 0                      , 0                            },
        .{ 0                             , 1 / tanHalfFOV, 0                      , 0                            },
        .{ 0                             , 0             , -(z_near + z_far)/zRange, 2 * z_far * z_near / zRange },
        .{ 0                             , 0             , 1                      , 0                            },
    }};
}


pub fn createOrthographic( left: f32, right: f32, bottom: f32, top: f32, near: f32, far: f32) Self {
	const width = right - left;
	const height = top - bottom;
	const depth = far - near;

    return Self{ .m =  .{
        .{ 2 / width, 0         , 0        , -(right+left) / width },
        .{ 0        , 2 / height, 0        , -(top+bottom) / height},
        .{ 0        , 0         , -2/depth , -(far+near) / depth   },
        .{ 0        , 0         , 0        , 1                     },
    }};
}

pub fn createTranslation(x: f32, y: f32, z: f32) Self {
    return Self { .m = .{
        .{ 1, 0, 0, x },
        .{ 0, 1, 0, y },
        .{ 0, 0, 1, z },
        .{ 0, 0, 0, 1 },
    }};
}

pub fn createRotation(x: f32, y: f32, z: f32, angle: f32) Self {

    const sin = std.math.sin(angle);
    const cos = std.math.cos(angle);
    return Self { .m = .{
        .{ cos + x * x * (1 - cos)    , x * y * (1 - cos) - z * sin, x * z * (1 - cos) + y * sin, 0 },
        .{ y * x * (1 - cos) + z * sin, cos + y * y * (1 - cos)    , y * z * (1 - cos) - x * sin, 0 },
        .{ z * x * (1 - cos) - y * sin, z * y * (1 - cos) + x * sin, cos + z * z * (1 - cos)    , 0 },
        .{ 0                          , 0                          , 0                          , 1 },
    }};
}

pub fn mul(self: *const Self, other: *const Self) Self {
    var res = Self.init();
    for (0..4) |i| {
        for (0..4) |j| {
            res.m[i][j] = self.m[i][0] * other.m[0][j] +
                            self.m[i][1] * other.m[1][j] +
                            self.m[i][2] * other.m[2][j] +
                            self.m[i][3] * other.m[3][j];
        }
    }
    return res;
}


pub fn transform(self : *const Self, r : *const Vector4f) Vector4f
{
    return Vector4f.init(
        self.m[0][0] * r.x + self.m[0][1] * r.y + self.m[0][2] * r.z + self.m[0][3] * r.w,
        self.m[1][0] * r.x + self.m[1][1] * r.y + self.m[1][2] * r.z + self.m[1][3] * r.w,
        self.m[2][0] * r.x + self.m[2][1] * r.y + self.m[2][2] * r.z + self.m[2][3] * r.w,
        self.m[3][0] * r.x + self.m[3][1] * r.y + self.m[3][2] * r.z + self.m[3][3] * r.w );
}
