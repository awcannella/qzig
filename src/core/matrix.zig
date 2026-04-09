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

        for (0..rows * cols) |i| {
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
            try m.set(i, i, Complex{ .re = 1.0, .im = 0.0 });
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
    pub fn getUnchecked(self: *Matrix, row: usize, col: usize) Complex {
        return self.data.atUnchecked(row * self.cols + col).*;
    }

    // Unchecked set for hot loops
    pub fn setUnchecked(self: *Matrix, row: usize, col: usize, value: Complex) void {
        self.data.atUnchecked(row * self.cols + col).* = value;
    }

    // Matrix addition
    pub fn add(self: *Matrix, other: *Matrix, allocator: *std.mem.Allocator) !Matrix {
        if (self.rows != other.rows or self.cols != other.cols) return error.DimensionMismatch;
        var result = try Matrix.zeros(allocator, self.rows, self.cols);
        for (0..self.rows) |i| {
            for (0..self.cols) |j| {
                const a = self.getUnchecked(i, j);
                const b = other.getUnchecked(i, j);
                result.setUnchecked(i, j, Complex{ .re = a.re + b.re, .im = a.im + b.im });
            }
        }
        return result;
    }

    // Matrix subtraction
    pub fn sub(self: *Matrix, other: *Matrix, allocator: *std.mem.Allocator) !Matrix {
        if (self.rows != other.rows or self.cols != other.cols) return error.DimensionMismatch;
        var result = try Matrix.zeros(allocator, self.rows, self.cols);
        for (0..self.rows) |i| {
            for (0..self.cols) |j| {
                const a = self.getUnchecked(i, j);
                const b = other.getUnchecked(i, j);
                result.setUnchecked(i, j, Complex{ .re = a.re - b.re, .im = a.im - b.im });
            }
        }
        return result;
    }

    // Scalar multiplication
    pub fn scalarMul(self: *Matrix, scalar: Complex) void {
        for (0..self.data.len) |i| {
            const a = self.data.atUnchecked(i);
            self.data.atUnchecked(i).* = Complex{
                .re = a.re * scalar.re - a.im * scalar.im,
                .im = a.re * scalar.im + a.im * scalar.re,
            };
        }
    }

    // Matrix multiplication (self * other)
    pub fn mul(self: *Matrix, other: *Matrix, allocator: *std.mem.Allocator) !Matrix {
        if (self.cols != other.rows) {
            return error.DimensionMismatch;
        }

        var result = try Matrix.zeros(allocator, self.rows, other.cols);

        for (0..self.rows) |i| {
            for (0..other.cols) |j| {
                var sum = Complex{ .re = 0.0, .im = 0.0 };

                for (0..self.cols) |k| {
                    const a = self.getUnchecked(i, k);
                    const b = other.getUnchecked(k, j);

                    sum = Complex{
                        .re = sum.re + (a.re * b.re - a.im * b.im),
                        .im = sum.im + (a.re * b.im + a.im * b.re),
                    };
                }
                result.setUnchecked(i, j, sum);
            }
        }
        return result;
    }
};
