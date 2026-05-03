const std = @import("std");

const qzig = @import("../lib.zig");
const runner = @import("runner.zig");
const BenchmarkResult = @import("benchmark_results.zig").BenchmarkResult;

const Circuit = qzig.Circuit;
const build_blocks = qzig.build_blocks;

fn buildCircuit(allocator: std.mem.Allocator, n: u32) !Circuit {
    var c = Circuit.init(allocator);

    var i: u32 = 0;
    while (i < n) : (i += 1) {
        try c.add_h(i);
    }

    return c;
}

pub fn runStreamingHBenchmark(
    allocator: std.mem.Allocator,
    max_q: u32,
    iterations: usize,
) !void {
    std.debug.print("\n=== STREAMING H BENCHMARK ===\n", .{});

    var q: u6 = 2;

    while (q <= max_q) : (q += 1) {
        var circuit = try buildCircuit(allocator, q);
        defer circuit.deinit();

        const plan = try circuit.compile(allocator);
        const blocks = try build_blocks(plan.ops.items, q, allocator);

        const result = try runner.runKernel(
            allocator,
            blocks,
            q,
            iterations,
        );

        const state_size: u64 = @as(u64, 1) << @intCast(q);

        const ns_per_op =
            @as(f64, @floatFromInt(result.total_ns)) /
            @as(f64, @floatFromInt(iterations));

        const bench = BenchmarkResult{
            .name = "streaming_h",
            .q = q,
            .state_size = state_size,
            .total_ns = result.total_ns,
            .ns_per_op = ns_per_op,
        };

        bench.print();
    }
}
