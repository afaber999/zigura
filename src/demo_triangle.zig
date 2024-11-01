const std = @import("std");
const common = @import("common.zig");
const Canvas = @import("Canvas.zig");
const Matrix4f = Canvas.Matrix4f;
const Vector4f = Canvas.Vector4f;
const Vertex = Canvas.Vertex;

const log = common.log;

canvas: Canvas = undefined,
allocator: std.mem.Allocator = undefined,
angle: f32 = 0,
projection : Matrix4f,

const Self = @This();

pub fn init(allocator: std.mem.Allocator, width: i32, height: i32) !Self {
    log("INIT from ZIG... {d} {d}\n", .{ width, height });

    const uw: usize = @intCast(width);
    const uh: usize = @intCast(height);
    const canvas = try Canvas.init(allocator, uw, uh, uw);

    const aspect = @as(f32,@floatFromInt(width)) / @as(f32,@floatFromInt(height));
    const near = 0.1;
    const far = 1000.0;

    const projection = Matrix4f.createPerspective( std.math.degreesToRadians(70.0), aspect, near, far);

    return Self{
        .canvas = canvas,
        .allocator = allocator,
        .projection = projection,
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

    self.angle += std.math.pi / 100.0;

    const translation = Matrix4f.createTranslation(0.0, 0.0, 3.0);
    const rotation = Matrix4f.createRotation(0.0, 1.0, 0.0, self.angle);
    const transform = self.projection.mul(&translation.mul(&rotation));

    const p1 = Vertex.initFromVector4f( &transform.transform( &Vector4f.init(-1,-1, 0, 1)));
    const p2 = Vertex.initFromVector4f( &transform.transform( &Vector4f.init( 0, 1, 0, 1)));
    const p3 = Vertex.initFromVector4f( &transform.transform( &Vector4f.init( 1,-1, 0, 1)));

    // AF TODO TRANSFORM
    self.canvas.clear(Canvas.from_rgba(0x20, 0x20, 0x20, 0xFF));
    self.canvas.fillTriangle(p1,p2,p3);

    // target.FillTriangle(maxYVert.Transform(transform), 
    //                 midYVert.Transform(transform), minYVert.Transform(transform));


    return true;
}
