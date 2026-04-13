const std = @import("std");
const qzig = @import("root.zig");

pub fn main() !void {
    var allocator = std.heap.page_allocator;

    const N: usize = 5;

    var A = try qzig.Matrix.zeros(&allocator, N, N);
    var B = try qzig.Matrix.zeros(&allocator, N, N);
    var C = try qzig.Matrix.zeros(&allocator, N, N);
    var C_ref = try qzig.Matrix.zeros(&allocator, N, N);

    defer {
        allocator.free(A.data.data);
        allocator.free(B.data.data);
        allocator.free(C.data.data);
        allocator.free(C_ref.data.data);
    }

    // =========================
    // Initialize matrices
    // =========================
    for (0..N) |i| {
        for (0..N) |j| {
            const ii: isize = @intCast(i);
            const jj: isize = @intCast(j);

            A.setUnchecked(i, j, .{ .re = @floatFromInt(ii + jj), .im = 0 });
            B.setUnchecked(i, j, .{ .re = @floatFromInt(ii - jj), .im = 0 });
        }
    }

    // =========================
    // SIMD workspace (needed for mul_into)
    // =========================
    const Vec = @Vector(4, f64);
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

    // =========================
    // Compute reference (naive)
    // =========================
    try A.mul_naive_into(&B, &C_ref);

    // =========================
    // Compute with dispatcher
    // =========================
    try A.mul_into(&B, &C, &workspace);

    // =========================
    // Compare results
    // =========================
    var ok = true;

    for (0..N) |i| {
        for (0..N) |j| {
            const a = C.getUnchecked(i, j);
            const b = C_ref.getUnchecked(i, j);

            const dr = a.re - b.re;
            const di = a.im - b.im;

            if ((if (dr < 0) -dr else dr) > 1e-9 or
                (if (di < 0) -di else di) > 1e-9)
            {
                ok = false;
            }
        }
    }
    if (ok) {
        std.debug.print("✅ mul_into is correct\n", .{});
    } else {
        std.debug.print("❌ mismatch detected\n", .{});
    }
}
