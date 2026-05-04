const std = @import("std");

const StateVector = @import("../src/core/state_vector.zig").StateVector;
const KernelBlock = @import("../src/core/kernel_block.zig").KernelBlock;
const PermWorkspace = @import("../src/core/kernel_types.zig").PermWorkspace;
const execute = @import("../src/core/simd_executor.zig").execute;

pub fn runKernel(
    allocator: std.mem.Allocator,
    blocks: []const KernelBlock,
    q: u32,
    iterations: usize,
) !RunResult {
    const size = @as(usize, 1) << @intCast(q);

    var state = try StateVector.init_zero(allocator, q);
    defer state.deinit(allocator);

    var workspace = PermWorkspace{
        .tmp_re = try allocator.alloc(f64, size),
        .tmp_im = try allocator.alloc(f64, size),
    };
    defer allocator.free(workspace.tmp_re);
    defer allocator.free(workspace.tmp_im);

    // ------------------------------------------------
    // ensure consistent initial state for warmup + run
    // ------------------------------------------------
    state.set_basis(0);

    // ----------------------------
    // warmup (stabilizes cache behavior)
    // ----------------------------
    const warmup_iters = @min(iterations, 10);

    var i: usize = 0;
    while (i < warmup_iters) : (i += 1) {
        execute(&state, blocks, &workspace);
    }

    // reset again so timing starts clean
    state.set_basis(0);

    // ----------------------------
    // timed region
    // ----------------------------
    const start = std.time.nanoTimestamp();

    i = 0;
    while (i < iterations) : (i += 1) {
        execute(&state, blocks, &workspace);
    }

    const end = std.time.nanoTimestamp();

    return .{
        .total_ns = end - start,
    };
}

pub const RunResult = struct {
    total_ns: i128,
};
