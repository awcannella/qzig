const std = @import("std");
const qzig = @import("root.zig");

const Vec = @Vector(4, f64);

// =========================================================
// Reset matrix (zero-out in place)
// =========================================================
fn resetMatrix(C: *qzig.Matrix) void {
    for (0..C.rows * C.cols) |i| {
        C.data.data[i] = qzig.Complex{ .re = 0.0, .im = 0.0 };
    }
}

// =========================================================
// Timing helpers (return ns instead of printing)
// =========================================================
fn benchmark_ns(
    func: fn (*qzig.Matrix, *qzig.Matrix, *qzig.Matrix) anyerror!void,
    A: *qzig.Matrix,
    B: *qzig.Matrix,
    C: *qzig.Matrix,
    iterations: usize,
) !i128 {
    for (0..200) |_| {
        try func(A, B, C);
    }

    const start = std.time.nanoTimestamp();

    for (0..iterations) |_| {
        try func(A, B, C);
    }

    return std.time.nanoTimestamp() - start;
}

fn benchmark_simd_ns(
    func: fn (*qzig.Matrix, *qzig.Matrix, *qzig.Matrix, *qzig.Matrix.SimdWorkspace) anyerror!void,
    A: *qzig.Matrix,
    B: *qzig.Matrix,
    C: *qzig.Matrix,
    workspace: *qzig.Matrix.SimdWorkspace,
    iterations: usize,
) !i128 {
    for (0..200) |_| {
        try func(A, B, C, workspace);
    }

    const start = std.time.nanoTimestamp();

    for (0..iterations) |_| {
        try func(A, B, C, workspace);
    }

    return std.time.nanoTimestamp() - start;
}

// =========================================================
// One full run (no printing)
// =========================================================
fn run_once(
    allocator: *std.mem.Allocator,
    N: usize,
    iterations: usize,
) !struct {
    naive: i128,
    small: i128,
    simd: i128,
} {
    var A = try qzig.Matrix.zeros(allocator, N, N);
    var B = try qzig.Matrix.zeros(allocator, N, N);
    var C = try qzig.Matrix.zeros(allocator, N, N);

    defer {
        allocator.free(A.data.data);
        allocator.free(B.data.data);
        allocator.free(C.data.data);
    }

    // init matrices (SAFE signed subtraction)
    for (0..N) |i| {
        for (0..N) |j| {
            const ii: isize = @intCast(i);
            const jj: isize = @intCast(j);

            A.setUnchecked(i, j, .{ .re = @floatFromInt(i + j), .im = 0 });
            B.setUnchecked(i, j, .{ .re = @floatFromInt(ii - jj), .im = 0 });
        }
    }

    const nB = (N + 3) / 4;

    var workspace = qzig.Matrix.SimdWorkspace{
        .a_re = try allocator.alloc(Vec, N * nB),
        .a_im = try allocator.alloc(Vec, N * nB),
        .b_re = try allocator.alloc(Vec, N * nB),
        .b_im = try allocator.alloc(Vec, N * nB),
    };

    defer {
        allocator.free(workspace.a_re);
        allocator.free(workspace.a_im);
        allocator.free(workspace.b_re);
        allocator.free(workspace.b_im);
    }

    resetMatrix(&C);
    const naive = try benchmark_ns(qzig.Matrix.mul_naive_into, &A, &B, &C, iterations);

    resetMatrix(&C);
    const small = try benchmark_ns(qzig.Matrix.mul_small_into, &A, &B, &C, iterations);

    resetMatrix(&C);
    const simd = try benchmark_simd_ns(qzig.Matrix.mul_simd_into, &A, &B, &C, &workspace, iterations);

    return .{
        .naive = naive,
        .small = small,
        .simd = simd,
    };
}

// =========================================================
// Averaged benchmark over multiple runs
// =========================================================
fn run_bench_for_size_avg(
    allocator: *std.mem.Allocator,
    N: usize,
    iterations: usize,
    repeats: usize,
) !void {
    var naive_total: i128 = 0;
    var small_total: i128 = 0;
    var simd_total: i128 = 0;

    for (0..repeats) |_| {
        const r = try run_once(allocator, N, iterations);
        naive_total += r.naive;
        small_total += r.small;
        simd_total += r.simd;
    }

    const d = @as(i128, @intCast(repeats));

    std.debug.print("\n================ N = {d} (avg over {d}) ================\n", .{ N, repeats });
    std.debug.print("naive: {d} ns\n", .{@divTrunc(naive_total, d)});
    std.debug.print("small: {d} ns\n", .{@divTrunc(small_total, d)});
    std.debug.print("simd : {d} ns\n", .{@divTrunc(simd_total, d)});
}

// =========================================================
// MAIN
// =========================================================
pub fn main() !void {
    var allocator = std.heap.page_allocator;

    const iterations: usize = 1_000;
    const repeats: usize = 100;

    const sizes = [_]usize{
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        9,
        10,
        11,
        12,
        13,
        14,
        15,
        16,
    };

    for (sizes) |N| {
        try run_bench_for_size_avg(&allocator, N, iterations, repeats);
    }
}
