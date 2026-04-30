const std = @import("std");

const StateVector = @import("../src/core/state_vector.zig").StateVector;
const KernelBlock = @import("../src/core/kernel_block.zig").KernelBlock;
const KernelTrace = @import("../src/core/kernel_types.zig").KernelTrace;
const PermWorkspace = @import("../src/core/kernel_types.zig").PermWorkspace;
const execute = @import("../src/core/executor.zig").execute;

pub fn runKernel(
    allocator: std.mem.Allocator,
    blocks: []const KernelBlock,
    q: u32,
    iterations: usize,
    trace: *KernelTrace,
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

    const start = std.time.nanoTimestamp();

    var i: usize = 0;
    while (i < iterations) : (i += 1) {
        execute(&state, blocks, &workspace, trace);
    }

    const end = std.time.nanoTimestamp();

    return .{
        .total_ns = end - start,
        .trace = trace.*,
    };
}

pub const RunResult = struct {
    total_ns: i128,
    trace: KernelTrace,
};
