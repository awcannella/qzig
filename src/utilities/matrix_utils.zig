const Matrix = @import("matrix.zig").Matrix;
const Complex = @import("complex.zig").Complex;
const std = @import("std");

pub fn identity(allocator: std.mem.Allocator, n: usize) !Matrix {
    var m = try Matrix.zeros(allocator, n, n);

    for (0..n) |i| {
        m.data[i * n + i] = .{ .re = 1.0, .im = 0.0 };
    }

    return m;
}

pub fn add(a: *Matrix, b: *Matrix, out: *Matrix) !void {
    if (a.rows != b.rows or a.cols != b.cols) return error.DimensionMismatch;

    for (0..a.data.len) |i| {
        const x = a.data[i];
        const y = b.data[i];

        out.data[i] = .{
            .re = x.re + y.re,
            .im = x.im + y.im,
        };
    }
}

pub fn sub(a: *Matrix, b: *Matrix, out: *Matrix) !void {
    if (a.rows != b.rows or a.cols != b.cols) return error.DimensionMismatch;

    for (0..a.data.len) |i| {
        const x = a.data[i];
        const y = b.data[i];

        out.data[i] = .{
            .re = x.re - y.re,
            .im = x.im - y.im,
        };
    }
}
