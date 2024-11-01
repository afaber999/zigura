const std = @import("std");
pub const Vertex = @import("Vertex.zig");
pub const Matrix4f = Vertex.Matrix4f;
pub const Vector4f = Vertex.Vector4f;

const log = @import("common.zig").log;
pub const Self = @This();
pub const PixelType = u32;


width: usize,
height: usize,
stride: usize,
pixels: []PixelType,
scanbuffer_left: [] usize,
scanbuffer_right: [] usize,
screen_transform : Matrix4f,
allocator : ?std.mem.Allocator = null,

fn f32toi32(f: f32) i32 {
    return @intFromFloat(f);
}

fn f32To(T:type,f: f32) T {
    return @intFromFloat(f);
}

pub fn init(allocator: std.mem.Allocator, width: usize, height: usize, stride: usize) !Self {
    const pixels = try allocator.alloc(PixelType, width * height);
    errdefer allocator.free(pixels);
    const scanbuffer_left = try allocator.alloc(usize, height);
    errdefer allocator.free(scanbuffer_left);
    const scanbuffer_right = try allocator.alloc(usize,height);
    errdefer allocator.free(scanbuffer_right);

    const hw  = @as(f32,@floatFromInt(width/2));
    const hh  = @as(f32,@floatFromInt(height/2));
    
    const screen_transform = Matrix4f.createScreenTransform(hw,hh);

    return .{
        .width = width,
        .height = height,
        .stride = stride,
        .pixels = pixels,
        .scanbuffer_left = scanbuffer_left,
        .scanbuffer_right = scanbuffer_right,
        .screen_transform = screen_transform,
        .allocator = allocator,
    };
}

pub fn deinit(self: Self) void {
    if (self.allocator) |allocator| {
        allocator.free(self.pixels);
        allocator.free(self.scanbuffer_left);
        allocator.free(self.scanbuffer_right);
    }
}

pub inline fn pixelIndex(self: Self, x: usize, y: usize) usize {
    return y * self.stride + x;
}

pub inline fn getPixel(self: Self, x: usize, y: usize) PixelType {
    return self.pixels[self.pixelIndex(x, y)];
}

pub inline fn setPixel(self: Self, x: usize, y: usize, color: PixelType) void {
    self.pixels[self.pixelIndex(x, y)] = color;
}

pub inline fn pixelPtr(self: Self, x: usize, y: usize) *PixelType {
    return &self.pixels[self.pixelIndex(x, y)];
}

pub inline fn red(color: PixelType) u8 {
    return @truncate(color >> 8 * 0);
}

pub inline fn green(color: PixelType) u8 {
    return @truncate(color >> 8 * 1);
}

pub inline fn blue(color: PixelType) u8 {
    return @truncate(color >> 8 * 2);
}

pub inline fn alpha(color: PixelType) u8 {
    return @truncate(color >> 8 * 3);
}

pub inline fn float(color: PixelType) f32 {
    return @as(*const f32, @ptrCast(&color)).*;
}

pub inline fn from_rgba(r: u8, g: u8, b: u8, a: u8) PixelType {
    return (@as(u32, r) << 8 * 0) | (@as(u32, g) << 8 * 1) | (@as(u32, b) << 8 * 2) | (@as(u32, a) << 8 * 3);
}

pub inline fn inBoundsX(self: Self, comptime T: type, x: T) bool {
    switch (T) {
        u32 => {
            const w: T = @intCast(self.width);
            return x < w;
        },
        i32 => {
            const w: T = @intCast(self.width);
            return 0 <= x and x < w;
        },
        else => @compileError(std.fmt.format("unsupported type: {}", .{T})),
    }
}

pub inline fn inBoundsY(self: Self, comptime T: type, y: T) bool {
    switch (T) {
        u32 => {
            const h: T = @intCast(self.height);
            return y < h;
        },
        i32 => {
            const h: T = @intCast(self.height);
            return 0 <= y and y < h;
        },
        else => @compileError(std.fmt.format("unsupported type: {}", .{T})),
    }
}

pub inline fn inBounds(self: Self, comptime T: type, x: T, y: T) bool {
    return (self.inBoundsX(T, x) and self.inBoundsY(T, y));
}

pub fn clear(self: *Self, color: PixelType) void {

    for (0..self.width * self.height) |i| {
        self.pixels[i] = color;
    }
}


pub fn drawScanBuffer(self : *Self,y:i32, x_min: i32, x_max: i32) void {    
    if (self.inBoundsY(i32,y)) {
        const xbmin = @min( @as(i32,@intCast( self.width-1 )), @max(0,x_min));
        const xbmax = @min( @as(i32,@intCast( self.width-1 )), @max(0,x_max));

        self.scanbuffer_left[@intCast(y)] = @intCast(xbmin);
        self.scanbuffer_right[@intCast(y)] = @intCast(xbmax); 
    }
}

pub fn fillShape(self : *Self, y_min:usize, y_max : usize ) void {
    for (y_min..y_max) |y| {
        const xs = self.scanbuffer_left[y];
        const xe = self.scanbuffer_right[y];

        //std.debug.print("y: {}, xs: {}, xe: {}\n",.{y, xs, xe});

        for (xs .. xe) |x| {
            self.setPixel(x, y, 0xFFFFFFFF);
        }
    }
}


pub fn scanConvertLine( self:*Self, miny : *const Vector4f, maxy: *const Vector4f, right_side : bool) void {

    const ys = f32To(usize, std.math.ceil(miny.y));
    const ye = f32To(usize, std.math.ceil(maxy.y));

    const dx = maxy.x - miny.x;
    const dy = maxy.y - miny.y;

    if (dy<=0.0) return;

    const scan_buffer = if (right_side) self.scanbuffer_right else self.scanbuffer_left;

    const x_step = dx / dy;
    const y_prestep = @as(f32,@floatFromInt(ys)) - miny.y;
    var cur_x = miny.x + x_step * y_prestep;

    for ( ys..ye) |y| {
        scan_buffer[ y ] = f32To(usize, std.math.ceil(cur_x));
        cur_x += x_step;
        //std.debug.print("y: {}, right side: {}, xb {}\n",.{idx, right_side, xb});
    }

}

pub fn scanConvertTriangle( self:*Self, miny: *const Vector4f, midy:*const Vector4f, maxy:*const Vector4f, ccw : bool) void {

    self.scanConvertLine(miny,maxy,ccw);
    self.scanConvertLine(miny,midy,!ccw);
    self.scanConvertLine(midy,maxy,!ccw);
}


pub fn fillTriangle( self:*Self, v1: Vertex, v2: Vertex, v3: Vertex) void {

   // const vt1 = self.screen_transform.transform(v1.position);

    const vt1 = self.screen_transform.transform(&v1.position).perspectiveDivide();
    const vt2 = self.screen_transform.transform(&v2.position).perspectiveDivide();
    const vt3 = self.screen_transform.transform(&v3.position).perspectiveDivide();
    
    var p0 : *const Vector4f = &vt1;
    var p1 : *const Vector4f = &vt2;
    var p2 : *const Vector4f = &vt3;

    if (p1.y < p0.y) std.mem.swap(*const Vector4f, &p1, &p0);
    if (p2.y < p1.y) std.mem.swap(*const Vector4f, &p2, &p1);
    if (p1.y < p0.y) std.mem.swap(*const Vector4f, &p1, &p0);

    const area = Vector4f.triangleArea(p0,p2,p1);
    const ccw  = (area >= 0.0);

    self.scanConvertTriangle(p0,p1,p2,ccw);
    //std.debug.print("======================== filling shape {} {}\n", .{p0.y, p2.y});
    self.fillShape(@intFromFloat(std.math.ceil(p0.y)),@intFromFloat(std.math.ceil(p2.y)));
}