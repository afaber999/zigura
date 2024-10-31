const std = @import("std");
const common = @import("common.zig");
const Canvas = @import("Canvas.zig");

const log = common.log;

canvas: Canvas = undefined,
allocator: std.mem.Allocator = undefined,
angle: f32 = 0,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Self {
    log("INIT from ZIG... {d} {d}\n", .{ width, height });

    const uw: usize = @intCast(width);
    const uh: usize = @intCast(height);
    const canvas = try Canvas.init(allocator, uw, uh, uw);

    return Self{
        .canvas = canvas,
        .allocator = allocator,
    };
}

pub fn pixel_ptr(self: Self) ?[*]Canvas.PixelType {
    return @ptrCast(self.canvas.pixelPtr(0,0));
}

pub fn deinit(self: Self) void {
    self.canvas.deinit();
}

pub fn render(self: *Self, dt: f32) bool {

    _ = dt;
    self.canvas.clear(Canvas.from_rgba(0x20, 0x20, 0x20, 0xFF));

    const p1 = Canvas.Vertex.init(100,100);
    const p2 = Canvas.Vertex.init(50,200);
    const p3 = Canvas.Vertex.init( 80,300);

    self.canvas.fillTriangle(p1,p2,p3);
    return true;
}
