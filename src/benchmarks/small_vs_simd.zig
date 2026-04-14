const std = @import("std");
const qzig = @import("qzig");

const Matrix = qzig.Matrix;

fn now() i128 {
    return std.time.nanoTimestamp();
}

fn fill(A: *Matrix, B: *Matrix) void {
    const n = A.rows * A.cols;

    for (0..n) |i| {
        const f = @as(f64, @floatFromInt(i));

        A.data[i] = .{ .re = @mod(f, 13.0), .im = @mod(f, 7.0) };
        B.data[i] = .{ .re = @mod(f, 5.0), .im = @mod(f, 11.0) };
    }
}

fn reset(C: *Matrix) void {
    for (C.data) |*x| {
        x.* = .{ .re = 0, .im = 0 };
    }
}

fn gflops(n: usize, iters: usize, sec: f64) f64 {
    const flops = 2.0 *
        @as(f64, @floatFromInt(n)) *
        @as(f64, @floatFromInt(n)) *
        @as(f64, @floatFromInt(n)) *
        @as(f64, @floatFromInt(iters));

    return flops / (sec * 1e9);
}

// --------------------
// BENCH SMALL
// --------------------
fn bench_small(A: *Matrix, B: *Matrix, C: *Matrix, iters: usize) !f64 {
    for (0..5) |_| {
        try qzig.Matrix.mul_small_into(A, B, C);
    }

    const start = now();

    for (0..iters) |_| {
        try qzig.Matrix.mul_small_into(A, B, C);
    }

    const sec = @as(f64, @floatFromInt(now() - start)) / 1e9;
    return sec;
}

// --------------------
// BENCH SIMD
// --------------------
fn bench_simd(A: *Matrix, B: *Matrix, C: *Matrix, workspace: *qzig.Matrix.SimdWorkspace, iters: usize) !f64 {
    for (0..5) |_| {
        try qzig.Matrix.mul_simd_into(A, B, C, workspace);
    }

    const start = now();

    for (0..iters) |_| {
        try qzig.Matrix.mul_simd_into(A, B, C, workspace);
    }

    const sec = @as(f64, @floatFromInt(now() - start)) / 1e9;
    return sec;
}

fn run(n: usize, iters: usize, workspace: *qzig.Matrix.SimdWorkspace) !void {
    var allocator = std.heap.page_allocator;

    var A = try Matrix.zeros(allocator, n, n);
    var B = try Matrix.zeros(allocator, n, n);
    var C = try Matrix.zeros(allocator, n, n);

    defer {
        allocator.free(A.data);
        allocator.free(B.data);
        allocator.free(C.data);
    }

    fill(&A, &B);
    reset(&C);

    const sec_small = try bench_small(&A, &B, &C, iters);
    const g_small = gflops(n, iters, sec_small);

    const sec_simd = try bench_simd(&A, &B, &C, workspace, iters);
    const g_simd = gflops(n, iters, sec_simd);

    std.debug.print("\nN={d}\n", .{n});
    std.debug.print("SMALL: {d:.3} ms | {d:.2} GFLOP/s\n", .{ sec_small * 1000.0, g_small });
    std.debug.print("SIMD : {d:.3} ms | {d:.2} GFLOP/s\n", .{ sec_simd * 1000.0, g_simd });
    std.debug.print("SPEEDUP: {d:.2}x\n", .{sec_small / sec_simd});
}

pub fn main() !void {
    const sizes = [_]usize{ 16, 32, 64, 128, 256, 512 };
    const iters = 10;

    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var workspace = qzig.Matrix.SimdWorkspace{
        .a_re = try arena.allocator().alloc(@Vector(4, f64), 512 * 512),
        .a_im = try arena.allocator().alloc(@Vector(4, f64), 512 * 512),
        .b_re = try arena.allocator().alloc(@Vector(4, f64), 512 * 512),
        .b_im = try arena.allocator().alloc(@Vector(4, f64), 512 * 512),
    };

    for (sizes) |n| {
        try run(n, iters, &workspace);
    }
}
