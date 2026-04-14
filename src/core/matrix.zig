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

    // -----------------------------------
    // SIMD + DISPATCH (UNCHANGED IDEA)
    // -----------------------------------
    pub const SimdWorkspace = struct {
        a_re: []@Vector(4, f64),
        a_im: []@Vector(4, f64),
        b_re: []@Vector(4, f64),
        b_im: []@Vector(4, f64),
    };

    pub fn mul_simd_into(self: *Matrix, other: *Matrix, result: *Matrix, workspace: *SimdWorkspace) !void {
        if (self.cols != other.rows or self.rows != result.rows or other.cols != result.cols) {
            return error.DimensionMismatch;
        }

        const Vec = @Vector(4, f64);

        const n = self.rows;
        const m = self.cols;
        const p = other.cols;

        const nB = (m + 3) / 4;

        // workspace safety check

        if (workspace.a_re.len < n * nB or workspace.b_re.len < p * nB) {
            return error.WorkspaceTooSmall;
        }

        const a_re = workspace.a_re;
        const a_im = workspace.a_im;
        const b_re = workspace.b_re;
        const b_im = workspace.b_im;

        // =========================================================
        // PACK A (row-major into vector blocks)
        // =========================================================
        for (0..n) |i| {
            for (0..m) |k| {
                const block = k / 4;
                const lane = k % 4;

                const a = self.data[i * m + k];

                a_re[i * nB + block][lane] = a.re;
                a_im[i * nB + block][lane] = a.im;
            }
        }

        // =========================================================
        // PACK B (column-major / transposed access pattern)
        // =========================================================
        for (0..p) |j| {
            for (0..m) |k| {
                const block = k / 4;
                const lane = k % 4;

                const b = other.data[k * p + j];

                b_re[j * nB + block][lane] = b.re;
                b_im[j * nB + block][lane] = b.im;
            }
        }

        // =========================================================
        // COMPUTE
        // =========================================================
        for (0..n) |i| {
            const row_c = i * p;

            for (0..p) |j| {
                var sum_re: Vec = @splat(0.0);
                var sum_im: Vec = @splat(0.0);

                for (0..nB) |k| {
                    const ar = a_re[i * nB + k];
                    const ai = a_im[i * nB + k];

                    const br = b_re[j * nB + k];
                    const bi = b_im[j * nB + k];

                    sum_re += ar * br - ai * bi;
                    sum_im += ar * bi + ai * br;
                }

                var re: f64 = 0.0;
                var im: f64 = 0.0;

                inline for (0..4) |lane| {
                    re += sum_re[lane];
                    im += sum_im[lane];
                }

                result.data[row_c + j] =
                    Complex{ .re = re, .im = im };
            }
        }
    }
    pub fn mul_into(self: *Matrix, other: *Matrix, result: *Matrix, workspace: ?*SimdWorkspace) !void {
        if (self.rows <= 6) {
            return self.mul_small_into(other, result);
        }

        if (workspace == null) return error.MissingSimdWorkspace;
        return self.mul_simd_into(other, result, workspace.?);
    }
};
