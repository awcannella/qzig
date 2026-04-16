const std = @import("std");
const Complex = @import("complex.zig").Complex;
const Vector = @import("vector.zig").Vector;

pub const Matrix = struct {
    rows: usize,
    cols: usize,
    data: []Complex,

    // Allocate a zero matrix
    pub fn zeros(allocator: std.mem.Allocator, rows: usize, cols: usize) !Matrix {
        const data = try allocator.alloc(Complex, rows * cols);

        for (data) |*v| {
            v.* = .{ .re = 0.0, .im = 0.0 };
        }

        return .{
            .rows = rows,
            .cols = cols,
            .data = data,
        };
    }

    pub fn deinit(self: *Matrix, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    //  HOT ACCESS (NO BOUNDS CHECKS)

    pub inline fn idx(self: *Matrix, r: usize, c: usize) usize {
        return r * self.cols + c;
    }

    pub inline fn get(self: *Matrix, r: usize, c: usize) *Complex {
        return &self.data[self.idx(r, c)];
    }

    // Scalar multiplication
    pub inline fn scalarMul(self: *Matrix, s: Complex) void {
        for (self.data) |*v| {
            v.* = .{
                .re = v.re * s.re - v.im * s.im,
                .im = v.re * s.im + v.im * s.re,
            };
        }
    }

    // =================================
    // QUANTUM CORE OPERATIONS
    // =================================

    const mul_2x2 = @import("../kernels/small/mul_2x2.zig").mul_2x2;

    pub fn mul_2x2_into(self: *Matrix, other: *Matrix, result: *Matrix) void {
        std.debug.assert(self.rows == 2 and self.cols == 2);
        std.debug.assert(other.rows == 2 and other.cols == 2);
        std.debug.assert(result.rows == 2 and result.cols == 2);

        mul_2x2(
            self.data.ptr,
            other.data.ptr,
            result.data.ptr,
        );
    }

    const mul_4x4 = @import("../kernels/small/mul_4x4.zig").mul_4x4;

    pub fn mul_4x4_into(self: *Matrix, other: *Matrix, result: *Matrix) void {
        std.debug.assert(self.rows == 4 and self.cols == 4);
        std.debug.assert(other.rows == 4 and other.cols == 4);
        std.debug.assert(result.rows == 4 and result.cols == 4);

        mul_4x4(
            self.data.ptr,
            other.data.ptr,
            result.data.ptr,
        );
    }

    // --------------------------------
    // GEMM (SMALL KERNEL)
    // --------------------------------
    pub fn mul_small_into(self: *Matrix, other: *Matrix, result: *Matrix) !void {
        const a = self.data;
        const b = other.data;
        const c = result.data;

        const m = self.cols;
        const n = self.rows;
        const p = other.cols;

        for (0..n) |i| {
            const row_a = i * m;
            const row_c = i * p;

            for (0..p) |j| {
                var sum_re: f64 = 0.0;
                var sum_im: f64 = 0.0;

                for (0..m) |k| {
                    const av = a[row_a + k];
                    const bv = b[k * p + j];

                    sum_re += av.re * bv.re - av.im * bv.im;
                    sum_im += av.re * bv.im + av.im * bv.re;
                }

                c[row_c + j] = Complex{ .re = sum_re, .im = sum_im };
            }
        }
    }

    pub fn mul_into(self: *Matrix, other: *Matrix, result: *Matrix) !void {
        if (self.rows <= 6) {
            return self.mul_small_into(other, result);
        }
    }
};
