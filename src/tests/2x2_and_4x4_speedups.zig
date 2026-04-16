const std = @import("std");
const qzig = @import("qzig");

const Matrix = qzig.Matrix;
const mul_2x2 = qzig.kernels.small.mul_2x2;
const mul_4x4 = qzig.kernels.small.mul_4x4;

// --------------------------------
// TIME
// --------------------------------
fn now() i128 {
    return std.time.nanoTimestamp();
}

// --------------------------------
// INIT MATRICES
// --------------------------------
fn fill(A: *Matrix, B: *Matrix) void {
    const n = A.rows * A.cols;

    for (0..n) |i| {
        const f = @as(f64, @floatFromInt(i));

        A.data[i] = .{
            .re = @mod(f, 13.0),
            .im = @mod(f, 7.0),
        };

        B.data[i] = .{
            .re = @mod(f, 5.0),
            .im = @mod(f, 11.0),
        };
    }
}

// --------------------------------
// RESET
// --------------------------------
fn reset(C: *Matrix) void {
    for (C.data) |*x| {
        x.* = .{ .re = 0, .im = 0 };
    }
}

// --------------------------------
// ERROR
// --------------------------------
fn diff(A: *Matrix, B: *Matrix) f64 {
    var max_err: f64 = 0.0;

    for (0..A.data.len) |i| {
        const dr = @abs(A.data[i].re - B.data[i].re);
        const di = @abs(A.data[i].im - B.data[i].im);
        const err = dr + di;

        if (err > max_err) max_err = err;
    }

    return max_err;
}

// --------------------------------
// BENCHMARK (direct call, no function pointers)
// --------------------------------
fn bench_2x2(
    A: *Matrix,
    B: *Matrix,
    C: *Matrix,
    iters: usize,
) f64 {
    var i: usize = 0;
    const start = now();

    while (i < iters) : (i += 1) {
        reset(C);
        mul_2x2(A.data.ptr, B.data.ptr, C.data.ptr);
    }

    const end = now();

    return @as(f64, @floatFromInt(end - start)) / 1e9;
}

fn bench_4x4(
    A: *Matrix,
    B: *Matrix,
    C: *Matrix,
    iters: usize,
) f64 {
    var i: usize = 0;
    const start = now();

    while (i < iters) : (i += 1) {
        reset(C);
        mul_4x4(A.data.ptr, B.data.ptr, C.data.ptr);
    }

    const end = now();

    return @as(f64, @floatFromInt(end - start)) / 1e9;
}

fn bench_small(
    A: *Matrix,
    B: *Matrix,
    C: *Matrix,
    iters: usize,
) !f64 {
    var i: usize = 0;
    const start = now();

    while (i < iters) : (i += 1) {
        reset(C);
        try Matrix.mul_small_into(A, B, C);
    }

    const end = now();

    return @as(f64, @floatFromInt(end - start)) / 1e9;
}

// --------------------------------
// RUN SINGLE TEST
// --------------------------------
fn run_4x4(iters: usize, allocator: std.mem.Allocator) !void {
    var A = try Matrix.zeros(allocator, 4, 4);
    var B = try Matrix.zeros(allocator, 4, 4);
    var C1 = try Matrix.zeros(allocator, 4, 4);
    var C2 = try Matrix.zeros(allocator, 4, 4);

    defer {
        allocator.free(A.data);
        allocator.free(B.data);
        allocator.free(C1.data);
        allocator.free(C2.data);
    }

    fill(&A, &B);

    // -------------------------
    // correctness check
    // -------------------------
    reset(&C1);
    mul_4x4(A.data.ptr, B.data.ptr, C1.data.ptr);

    reset(&C2);
    try Matrix.mul_small_into(&A, &B, &C2);

    const err = diff(&C1, &C2);

    // -------------------------
    // warmup
    // -------------------------
    for (0..10_000) |_| {
        reset(&C1);
        mul_4x4(A.data.ptr, B.data.ptr, C1.data.ptr);
    }

    for (0..10_000) |_| {
        reset(&C2);
        try Matrix.mul_small_into(&A, &B, &C2);
    }

    // -------------------------
    // benchmark
    // -------------------------
    const t_kernel = bench_4x4(&A, &B, &C1, iters);
    const t_small = try bench_small(&A, &B, &C2, iters);

    std.debug.print("\n=== 4x4 Benchmark ===\n", .{});
    std.debug.print("kernel mul_4x4 : {d:.6} s\n", .{t_kernel});
    std.debug.print("matrix small   : {d:.6} s\n", .{t_small});
    std.debug.print("speedup        : {d:.3}x\n", .{t_small / t_kernel});
    std.debug.print("error          : {d}\n", .{err});
}

fn run_2x2(iters: usize, allocator: std.mem.Allocator) !void {
    var A = try Matrix.zeros(allocator, 2, 2);
    var B = try Matrix.zeros(allocator, 2, 2);
    var C1 = try Matrix.zeros(allocator, 2, 2);
    var C2 = try Matrix.zeros(allocator, 2, 2);

    defer {
        allocator.free(A.data);
        allocator.free(B.data);
        allocator.free(C1.data);
        allocator.free(C2.data);
    }

    fill(&A, &B);

    // -------------------------
    // correctness check
    // -------------------------
    reset(&C1);
    mul_2x2(A.data.ptr, B.data.ptr, C1.data.ptr);

    reset(&C2);
    try Matrix.mul_small_into(&A, &B, &C2);

    const err = diff(&C1, &C2);

    // -------------------------
    // warmup
    // -------------------------
    for (0..10_000) |_| {
        reset(&C1);
        mul_2x2(A.data.ptr, B.data.ptr, C1.data.ptr);
    }

    for (0..10_000) |_| {
        reset(&C2);
        try Matrix.mul_small_into(&A, &B, &C2);
    }

    // -------------------------
    // benchmark
    // -------------------------
    const t_kernel = bench_2x2(&A, &B, &C1, iters);
    const t_small = try bench_small(&A, &B, &C2, iters);

    std.debug.print("\n=== 2x2 Benchmark ===\n", .{});
    std.debug.print("kernel mul_2x2 : {d:.6} s\n", .{t_kernel});
    std.debug.print("matrix small   : {d:.6} s\n", .{t_small});
    std.debug.print("speedup        : {d:.3}x\n", .{t_small / t_kernel});
    std.debug.print("error          : {d}\n", .{err});
}

// --------------------------------
// MAIN
// --------------------------------
pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // fixed iteration count for stability
    const iters: usize = 1_000_000;

    try run_2x2(iters, allocator);
    try run_4x4(iters, allocator);

    std.debug.print("\nDone.\n", .{});

    const builtin = @import("builtin");
    if (builtin.mode != .ReleaseFast) {
        @compileError("NOT IN RELEASEFAST");
    }
}
