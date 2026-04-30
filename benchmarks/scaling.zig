const std = @import("std");

const qzig = @import("../lib.zig");
const runner = @import("runner.zig");
const metrics = @import("metrics.zig");

const Circuit = qzig.Circuit;
const build_blocks = qzig.build_blocks;
const KernelTrace = qzig.KernelTrace;

//
// =====================================================
// CIRCUIT GENERATOR
// =====================================================
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

        // CNOT chain
        i = 0;
        while (i < n - 1) : (i += 1) {
            try c.add_cnot(i, i + 1);
        }

        // Z layer
        i = 1;
        while (i < n) : (i += 2) {
            try c.add_z(i);
        }
    }

    return c;
}

//
// =====================================================
// BENCHMARK DRIVER
// =====================================================
//

pub fn runScalingBenchmark(
    allocator: std.mem.Allocator,
    max_q: u32,
    iterations: usize,
) !void {
    std.debug.print("\n=== QUANTUM KERNEL BENCHMARK ===\n", .{});
    std.debug.print("q | state | ns/op | GB/s\n", .{});

    var q: u32 = 2;

    while (q <= max_q) : (q += 1) {

        // -------------------------
        // Build circuit
        // -------------------------
        var circuit = try buildCircuit(allocator, q);
        defer circuit.deinit();

        const plan = try circuit.compile(allocator);
        const blocks = try build_blocks(plan.ops.items, allocator);

        // -------------------------
        // Run benchmark
        // -------------------------
        var trace = KernelTrace{};

        const result = try runner.runKernel(
            allocator,
            blocks,
            q,
            iterations,
            &trace,
        );

        const state_size = @as(u64, 1) << @intCast(q);

        const total_ns: f64 = @floatFromInt(result.total_ns);
        const ns_per_op = total_ns / @as(f64, @floatFromInt(iterations));

        const seconds = total_ns / 1e9;

        const m = metrics.compute(
            trace,
            state_size,
            seconds,
        );

        const gb_per_sec = m.gb_per_sec;

        // -------------------------
        // PRINT CLEAN RESULTS
        // -------------------------
        std.debug.print(
            "{d} | {d} | {d:.2} | {d:.3}\n",
            .{
                q,
                state_size,
                ns_per_op,
                gb_per_sec,
            },
        );
    }
}
