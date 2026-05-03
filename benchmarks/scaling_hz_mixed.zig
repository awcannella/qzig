const std = @import("std");

const qzig = @import("../lib.zig");
const runner = @import("runner.zig");

const BenchmarkResult = @import("benchmark_results.zig").BenchmarkResult;

const Circuit = qzig.Circuit;
const build_blocks = qzig.build_blocks;

//
// ===========================
// CIRCUIT: HZ MIXED
// ===========================
//

fn buildCircuit(allocator: std.mem.Allocator, n: u32) !Circuit {
    var c = Circuit.init(allocator);

    var depth: u32 = 0;
    while (depth < 2) : (depth += 1) {

        // H layer
        var i: u32 = 0;
        while (i < n) : (i += 2) {
            try c.add_h(i);
        }

        // Z phase layer (offset)
        i = 1;
        while (i < n) : (i += 2) {
            try c.add_z(i);
        }

        // light entanglement
        i = 0;
        while (i < n - 1) : (i += 2) {
            try c.add_cnot(i, i + 1);
        }
    }

    return c;
}

//
// ===========================
// DRIVER
// ===========================
//

pub fn runHZBenchmark(
    allocator: std.mem.Allocator,
    max_q: u32,
    iterations: usize,
) !void {
    std.debug.print("\n=== HZ MIXED BENCHMARK ===\n", .{});

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

        const bench_result = BenchmarkResult{
            .name = "hz_mixed",
            .q = q,
            .state_size = state_size,
            .total_ns = result.total_ns,
            .ns_per_op = ns_per_op,
        };

        bench_result.print();
    }
}
