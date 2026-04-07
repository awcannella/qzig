const std = @import("std");
const qzig = @import("root.zig"); // root of the library

pub fn main() !void {
    const z1 = qzig.math.Complex.init(1.0, 2.0);
    const z2 = qzig.math.Complex.init(3.0, 4.0);

    // Addition
    const addResult = z1.add(z2);
    std.debug.print("\nz1 + z2 = {d} + {d}i\n\n", .{ addResult.re, addResult.im });

    // Multiplication
    const mulResult = z1.mul(z2);
    std.debug.print("\nResult: {d} + {d}i\n\n", .{ mulResult.re, mulResult.im });

    // Conjugate
    const conjResult = z1.conj();
    std.debug.print("\nconj(z1) = {d} + {d}i\n\n", .{ conjResult.re, conjResult.im });

    // Norm
    const normResult = z1.norm();
    std.debug.print("\n|z1|^2 = {d}\n\n", .{normResult});

    // Absoulte value
    const absResult = z1.abs();
    std.debug.print("\n|z1| = {d}\n\n", .{absResult});

    // Argument
    const argResult = z1.arg();
    std.debug.print("\narg(z1) = {d} radians\n\n", .{argResult});

    // Polar
    const polarResult = qzig.math.Complex.polar(absResult, argResult);
    std.debug.print("\npolar(|z1|, arg(z1)) = {d} + {d}i\n\n", .{ polarResult.re, polarResult.im });

    // Projection
    const infZ = qzig.math.Complex.init(std.math.inf(f64), 2.0);
    const projResult = infZ.proj();
    std.debug.print("\nproj(inf + 2i) = {d} + {d}i\n\n", .{ projResult.re, projResult.im });
}
