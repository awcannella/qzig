const std = @import("std");
const Complex = @import("complex.zig").Complex;
const Vector = @import("vector.zig").Vector;

pub const Matrix = struct {
    rows: usize,
    cols: usize,
    data: Vector(Complex), // uses generic Vector for storage

    // Allocate a zero matrix
    pub fn zeros(allocator: *std.mem.Allocator, rows: usize, cols: usize) !Matrix {
        var data = try Vector(Complex).init(allocator, rows * cols);

        var i: usize = 0;
        while (i < rows * cols) : (i += 1) {
            data.data[i] = Complex{ .re = 0.0, .im = 0.0 };
        }
        data.len = rows * cols;

        return Matrix{
            .rows = rows,
            .cols = cols,
            .data = data,
        };
    }

    // Identity matrix
    pub fn identity(allocator: *std.mem.Allocator, size: usize) !Matrix {
        var m = try Matrix.zeros(allocator, size, size);
        for (0..size) |i| {
            m.data.atUnchecked(i * size + i).* = Complex{ .re = 1.0, .im = 0.0 };
        }
        return m;
    }

    // Create from existing slice (row-major)
    pub fn fromSlice(rows: usize, cols: usize, slice: []Complex) Matrix {
        const data = Vector(Complex).fromSlice(slice);
        return Matrix{ .rows = rows, .cols = cols, .data = data };
    }

    // Get element at (row, col)
    pub fn get(self: *Matrix, row: usize, col: usize) !Complex {
        return self.data.at(row * self.cols + col);
    }

    // Set element at (row, col)
    pub fn set(self: *Matrix, row: usize, col: usize, value: Complex) !void {
        try self.data.set(row * self.cols + col, value);
    }

    // Unchecked get for hot loops
    pub inline fn getUnchecked(self: *Matrix, row: usize, col: usize) Complex {
        return self.data.atUnchecked(row * self.cols + col).*;
    }

    // Unchecked set for hot loops
    pub inline fn setUnchecked(self: *Matrix, row: usize, col: usize, value: Complex) void {
        self.data.atUnchecked(row * self.cols + col).* = value;
    }

    // Matrix addition
    pub fn add(self: *Matrix, other: *Matrix, allocator: *std.mem.Allocator) !Matrix {
        if (self.rows != other.rows or self.cols != other.cols) return error.DimensionMismatch;
        var result = try Matrix.zeros(allocator, self.rows, self.cols);

        const rows = self.rows;
        const cols = self.cols;

        for (0..rows) |i| {
            const row_start = i * cols;
            for (0..self.cols) |j| {
                const idx = row_start + j;
                const a = self.data.atUnchecked(idx).*;
                const b = other.data.atUnchecked(idx).*;
                result.data.atUnchecked(idx).* = Complex{ .re = a.re + b.re, .im = a.im + b.im };
            }
        }
        return result;
    }

    // Matrix subtraction
    pub fn sub(self: *Matrix, other: *Matrix, allocator: *std.mem.Allocator) !Matrix {
        if (self.rows != other.rows or self.cols != other.cols) return error.DimensionMismatch;
        var result = try Matrix.zeros(allocator, self.rows, self.cols);

        const rows = self.rows;
        const cols = self.cols;

        for (0..rows) |i| {
            const row_start = i * cols;
            for (0..self.cols) |j| {
                const idx = row_start + j;
                const a = self.data.atUnchecked(idx).*;
                const b = other.data.atUnchecked(idx).*;
                result.data.atUnchecked(idx).* = Complex{ .re = a.re - b.re, .im = a.im - b.im };
            }
        }
        return result;
    }

    // Scalar multiplication
    pub inline fn scalarMul(self: *Matrix, scalar: Complex) void {
        for (0..self.data.len) |i| {
            const a = self.data.atUnchecked(i).*;
            self.data.atUnchecked(i).* = Complex{
                .re = a.re * scalar.re - a.im * scalar.im,
                .im = a.re * scalar.im + a.im * scalar.re,
            };
        }
    }

    // Matrix multiplication (self * other)
    pub fn mul_naive_into(self: *Matrix, other: *Matrix, result: *Matrix) !void {
        if (self.cols != other.rows or self.rows != result.rows or other.cols != result.cols) {
            return error.DimensionMismatch;
        }

        const m = self.cols;
        const n = self.rows;
        const p = other.cols;

        for (0..n) |i| {
            const a_row = i * m;
            const c_row = i * p;

            for (0..p) |j| {
                var sum_re: f64 = 0.0;
                var sum_im: f64 = 0.0;

                var b_idx: usize = j; // starts at column j

                for (0..m) |_| {
                    const a = self.data.atUnchecked(a_row + (b_idx % m)).*;
                    const b = other.data.atUnchecked(b_idx).*;

                    sum_re += a.re * b.re - a.im * b.im;
                    sum_im += a.re * b.im + a.im * b.re;

                    b_idx += other.cols;
                }
                result.data.atUnchecked(c_row + j).* =
                    Complex{ .re = sum_re, .im = sum_im };
            }
        }
    }

    // Matrix multiplication (self * other)
    pub fn mul_small_into(
        self: *Matrix,
        other: *Matrix,
        result: *Matrix,
    ) !void {
        if (self.cols != other.rows or
            self.rows != result.rows or
            other.cols != result.cols)
        {
            return error.DimensionMismatch;
        }

        const a = self.data.data;
        const b = other.data.data;
        const c = result.data.data;

        const m = self.cols;
        const n = self.rows;
        const p = other.cols;

        for (0..n) |i| {
            const row_a = i * m;
            const row_c = i * p;

            for (0..p) |j| {
                var sum_re: f64 = 0.0;
                var sum_im: f64 = 0.0;

                var b_idx: usize = j;

                for (0..m) |_| {
                    const av = a[row_a + b_idx % m];
                    const bv = b[b_idx];

                    sum_re += av.re * bv.re - av.im * bv.im;
                    sum_im += av.re * bv.im + av.im * bv.re;

                    b_idx += other.cols;
                }

                c[row_c + j] = Complex{
                    .re = sum_re,
                    .im = sum_im,
                };
            }
        }
    }

    pub const SimdWorkspace = struct {
        a_re: []@Vector(4, f64),
        a_im: []@Vector(4, f64),
        b_re: []@Vector(4, f64),
        b_im: []@Vector(4, f64),
    };

    pub fn mul_simd_into(
        self: *Matrix,
        other: *Matrix,
        result: *Matrix,
        workspace: *SimdWorkspace,
    ) !void {
        if (self.cols != other.rows or
            self.rows != result.rows or
            other.cols != result.cols)
        {
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

                const a = self.data.atUnchecked(i * m + k).*;

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

                const b = other.data.atUnchecked(k * p + j).*;

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

                result.data.atUnchecked(row_c + j).* =
                    Complex{ .re = re, .im = im };
            }
        }
    }
    pub fn mul_into(
        self: *Matrix,
        other: *Matrix,
        result: *Matrix,
        workspace: ?*SimdWorkspace,
    ) !void {
        const N = self.rows;

        // safety check (same as others)
        if (self.cols != other.rows or
            self.rows != result.rows or
            other.cols != result.cols)
        {
            return error.DimensionMismatch;
        }

        // =========================
        // Dispatch based on size
        // =========================
        if (N <= 6) {
            // small matrices → cache-friendly scalar wins
            return self.mul_small_into(other, result);
        } else {
            // larger matrices → SIMD wins
            if (workspace == null) {
                return error.MissingSimdWorkspace;
            }
            return self.mul_simd_into(other, result, workspace.?);
        }
    }
};
