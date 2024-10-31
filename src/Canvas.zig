const std = @import("std");
pub const Vertex = @import("Vertex.zig");
const log = @import("common.zig").log;
pub const Self = @This();
pub const PixelType = u32;


width: usize,
height: usize,
stride: usize,
pixels: []PixelType,
scanbuffer_left: [] usize,
scanbuffer_right: [] usize,
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

    return .{
        .width = width,
        .height = height,
        .stride = stride,
        .pixels = pixels,
        .scanbuffer_left = scanbuffer_left,
        .scanbuffer_right = scanbuffer_right,
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


pub fn scanConvertLine( self:*Self, minY : *const Vertex, maxY: *const Vertex, right_side : bool) void {

    const ys = f32toi32(minY.y);
    const ye = f32toi32(maxY.y);

    const xs = f32toi32(minY.x);
    const xe = f32toi32(maxY.x);

    const dx = xe - xs;
    const dy = ye - ys;

    if (dy<=0.0) return;

    const scan_buffer = if (right_side) self.scanbuffer_right else self.scanbuffer_left;

    for (0..@as(usize,@intCast(dy))) |y| {
    
        const x = xs + @divFloor(@as(i32,@intCast(y)) * dx, dy);
        const xb = @min( self.width-1, @as(usize, @intCast( @max(0,x))));

        const idx = (y + @as(usize, @intCast(ys))); 
        scan_buffer[ idx ] = xb;
        //std.debug.print("y: {}, right side: {}, xb {}\n",.{idx, right_side, xb});
    }

}

pub fn scanConvertTriangle( self:*Self, minY: *const Vertex, midY:*const Vertex, maxY:*const Vertex, ccw : bool) void {

    self.scanConvertLine(minY,maxY,ccw);
    self.scanConvertLine(minY,midY,!ccw);
    self.scanConvertLine(midY,maxY,!ccw);
}


pub fn fillTriangle( self:*Self, minY: Vertex, midY: Vertex, maxY: Vertex) void {

    var p0 : *const Vertex = &minY;
    var p1 : *const Vertex = &midY;
    var p2 : *const Vertex  = &maxY;

    if (p1.y < p0.y) std.mem.swap(*const Vertex, &p1, &p0);
    if (p2.y < p1.y) std.mem.swap(*const Vertex, &p2, &p1);
    if (p1.y < p0.y) std.mem.swap(*const Vertex, &p1, &p0);

    const area = Vertex.triangleArea(p0,p2,p1);
    const ccw  = (area >= 0.0);

    self.scanConvertTriangle(p0,p1,p2,ccw);
    //std.debug.print("======================== filling shape {} {}\n", .{p0.y, p2.y});
    self.fillShape(@intFromFloat(p0.y),@intFromFloat(p2.y));
}