const std = @import("std");
const qzig = @import("root.zig"); // your library root

pub fn main() !void {
    var gpa = std.heap.page_allocator;

    // ------------------------
    // Test Vector<f64>
    // ------------------------
    var vf64 = try qzig.math.Vector(f64).init(&gpa, 2);
    defer vf64.deinit();

    try vf64.push(10.0);
    try vf64.push(20.0);
    std.debug.print("vf64 length = {}\n", .{vf64.getLen()});
    std.debug.print("vf64[0] = {}, vf64[1] = {}\n", .{ vf64.data[0], vf64.data[1] });

    const popped_f64 = try vf64.pop();
    std.debug.print("Popped from vf64: {}\n", .{popped_f64});
    std.debug.print("vf64 length now = {}\n\n", .{vf64.getLen()});

    // ------------------------
    // Test Vector<Complex>
    // ------------------------
    var vc = try qzig.math.Vector(qzig.math.Complex).init(&gpa, 2);
    defer vc.deinit();

    try vc.push(qzig.math.Complex.init(1, 1));
    try vc.push(qzig.math.Complex.init(2, 2));
    std.debug.print("vc length = {}\n", .{vc.getLen()});
    std.debug.print("vc[0] = {} + {}i, vc[1] = {} + {}i\n", .{ vc.data[0].re, vc.data[0].im, vc.data[1].re, vc.data[1].im });

    const popped_c = try vc.pop();
    std.debug.print("Popped from vc: {} + {}i\n", .{ popped_c.re, popped_c.im });
    std.debug.print("vc length now = {}\n", .{vc.getLen()});
}
