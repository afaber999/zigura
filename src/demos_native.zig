const std = @import("std");
const c = @cImport({
    @cInclude("fenster.h");
});
const Canvas = @import("Canvas.zig");

const Triangle = @import("demo_triangle.zig");

const Demo = union(enum) {
    triangle: Triangle,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();

    const width = 800;
    const height = 600;

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        std.debug.print("Usage: {s} <demo>\n", .{args[0]});
        return;
    }

    // nedded for ARGB to RGBA conversion
    var fenster_buffer = try allocator.alloc(u32, width * height);
    var canvas: Canvas = undefined;

    var demo: Demo = undefined;

    const demoName = args[1];
    if (std.mem.eql(u8, demoName, "dot3d")) {
    } else if (std.mem.eql(u8, demoName, "triangle")) {
        demo = Demo{ .triangle = try Triangle.init(allocator, width, height) };
        canvas = demo.triangle.canvas;
    } else {
        return error.Unreachable;
    }

    defer switch (demo) {
        .triangle => demo.triangle.deinit(),
    };

    var f : c.fenster = .{
        .width = width,
        .height = height,
        .title = "DEMO window",
        .buf = fenster_buffer.ptr,
    };

    _ = c.fenster_open(&f);
    defer c.fenster_close(&f);

    var now: i64 = c.fenster_time();
    var prev: i64 = now;

    while (c.fenster_loop(&f) == 0) {
        const dt: f32 = @floatFromInt(now - prev);
        prev = now;

        _ = switch (demo) {
            .triangle => demo.triangle.render(dt),
        };

        var idx: usize = 0;
        for (0..canvas.height) |y| {
            for (0..canvas.width) |x| {
                const pixel = canvas.getPixel(x,y);
                fenster_buffer[idx] = Canvas.from_rgba(Canvas.blue(pixel), Canvas.green(pixel), Canvas.red(pixel), 255);
                idx += 1;
            }
        }

        // Exit when Escape is pressed
        if (f.keys[27] != 0) {
            break;
        }
        // Keep ~60 FPS
        const diff: i64 = 1000 / 60 - (c.fenster_time() - now);
        if (diff > 0) {
            c.fenster_sleep(diff);
        }
        now = c.fenster_time();
    }
}

const Self = @This();
