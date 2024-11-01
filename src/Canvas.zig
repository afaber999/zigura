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
screen_transform : Matrix4f,
allocator : ?std.mem.Allocator = null,

fn f32toi32(f: f32) i32 {
    return @intFromFloat(f);
}

fn f32To(T:type,f: f32) T {
    return @intFromFloat(f);
}

fn tof32(i: anytype) f32 {
    return @floatFromInt(i);
}

const Edge = struct {
    x_cur: f32,
    x_step: f32,
    y_start: usize,
    y_end: usize,

    pub fn init(min_y: Vector4f, max_y: Vector4f) Edge {
        
        const ys = f32To(usize, std.math.ceil(min_y.y));
        const ye = f32To(usize, std.math.ceil(max_y.y));
        const dx = max_y.x - min_y.x;
        const dy = max_y.y - min_y.y;

        // todo ASSERT dy<=0.0
        const x_step = dx / dy;
        const y_prestep = tof32(ys) - min_y.y;
        const x_cur = min_y.x + x_step * y_prestep;

        return .{ .x_cur = x_cur, .x_step = x_step, .y_start = ys, .y_end = ye };
    }

    pub fn step(self: *Edge) void {
        self.x_cur += self.x_step;
    }
};


pub fn init(allocator: std.mem.Allocator, width: usize, height: usize, stride: usize) !Self {
    const pixels = try allocator.alloc(PixelType, width * height);
    errdefer allocator.free(pixels);

    const hw  = @as(f32,@floatFromInt(width/2));
    const hh  = @as(f32,@floatFromInt(height/2));
    
    const screen_transform = Matrix4f.createScreenTransform(hw,hh);

    return .{
        .width = width,
        .height = height,
        .stride = stride,
        .pixels = pixels,
        .screen_transform = screen_transform,
        .allocator = allocator,
    };
}

pub fn deinit(self: Self) void {
    if (self.allocator) |allocator| {
        allocator.free(self.pixels);
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

pub fn scanConvertTriangle( self:*Self, miny: *const Vector4f, midy:*const Vector4f, maxy:*const Vector4f, ccw : bool) void {

    self.scanConvertLine(miny,maxy,ccw);
    self.scanConvertLine(miny,midy,!ccw);
    self.scanConvertLine(midy,maxy,!ccw);
}

pub fn scanEdges( self:*Self, edge_a: *Edge, edge_b: *Edge, right_side : bool) void {

    const left_edge = if (right_side) edge_b else edge_a;
    const right_edge = if (right_side) edge_a else edge_b;

    const ys = edge_b.y_start;
    const ye = edge_b.y_end;

    for (ys..ye) |y| {
        self.drawScanLine(left_edge, right_edge, y);
        left_edge.step();
        right_edge.step();
    }
}


pub fn scanTriangle( self:*Self, miny: *const Vector4f, midy:*const Vector4f, maxy:*const Vector4f, ccw : bool) void {

    var t2b = Edge.init(miny.*,maxy.*);
    var t2m = Edge.init(miny.*,midy.*);
    var m2b = Edge.init(midy.*,maxy.*);

    self.scanEdges(&t2b,&t2m,ccw);
    self.scanEdges(&t2b,&m2b,ccw);
}


pub fn drawScanLine(self: *Self,left_edge : *const Edge, right_edge : *const Edge, y : usize) void {    

    const xs = left_edge.x_cur;
    const xe = right_edge.x_cur;

    // AF TODO check bounds conditions?
    for ( f32To(usize,xs) .. f32To(usize,xe)) |x| {
        self.setPixel(x, y, 0xFFFFFFFF);
    }
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

     self.scanTriangle(p0,p1,p2,ccw);
    //std.debug.print("======================== filling shape {} {}\n", .{p0.y, p2.y});
    //self.fillShape(@intFromFloat(std.math.ceil(p0.y)),@intFromFloat(std.math.ceil(p2.y)));
}
