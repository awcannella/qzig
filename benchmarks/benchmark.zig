const std = @import("std");

const qzig = @import("../lib.zig");

const Circuit = qzig.Circuit;
const build_blocks = qzig.build_blocks;
const execute = qzig.execute;

const StateVector = qzig.StateVector;
const KernelBlock = qzig.KernelBlock;

const KernelTrace = qzig.KernelTrace;
const PermWorkspace = qzig.PermWorkspace;

//
// =====================================================
// BOTTLENECK MODEL
// =====================================================
//

pub const Bottleneck = enum {
    compute_bound,
    transition,
    memory_bound,
};

fn classifyAI(ai: f64) Bottleneck {
    if (ai > 1.0) return .compute_bound;
    if (ai > 0.1) return .transition;
    return .memory_bound;
}

fn bottleneckStr(b: Bottleneck) []const u8 {
    return switch (b) {
        .compute_bound => "compute",
        .transition => "transition",
        .memory_bound => "memory",
    };
}

//
// =====================================================
// BENCH RESULT
// =====================================================
//

pub const BenchResult = struct {
    q: u32,
    state_size: usize,

    avg_ns: f64,
    total_ns: i128,

    flops: u64,
    bytes: u64,

    flops_per_sec: f64,
    gb_per_sec: f64,
    ai: f64,

    perm_ratio: f64,
    h_ratio: f64,
    z_ratio: f64,

    bottleneck: Bottleneck,
};

//
// =====================================================
// MIXED QUANTUM BENCH CIRCUIT
// =====================================================
//

fn buildCircuit(allocator: std.mem.Allocator, n: u32) !Circuit {
    var c = Circuit.init(allocator);

    var depth: u32 = 0;
    while (depth < 2) : (depth += 1) {

        // -------------------------
        // H layer (superposition)
        // -------------------------
        var i: u32 = 0;
        while (i < n) : (i += 2) {
            try c.add_h(i);
        }

        // -------------------------
        // Entangling layer (CNOT chain)
        // -------------------------
        i = 0;
        while (i < n - 1) : (i += 1) {
            try c.add_cnot(i, i + 1);
        }

        // -------------------------
        // Phase layer (Z gates)
        // -------------------------
        i = 1;
        while (i < n) : (i += 2) {
            try c.add_z(i);
        }
    }

    return c;
}

//
// =====================================================
// RUN KERNEL
// =====================================================
//

fn runKernel(
    allocator: std.mem.Allocator,
    blocks: []const KernelBlock,
    q: u32,
    iterations: usize,
    trace: *KernelTrace,
) !i128 {
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
    return end - start;
}

//
// =====================================================
// METRICS
// =====================================================
//

fn computeMetrics(trace: KernelTrace, state_size: u64) struct {
    flops: u64,
    bytes: u64,
} {
    return .{
        .flops = trace.hadamard_ops * (8 * state_size) +
            trace.zphase_ops * (2 * state_size) +
            trace.perm_ops * (1 * state_size),

        .bytes = trace.hadamard_ops * (32 * state_size) +
            trace.zphase_ops * (16 * state_size) +
            trace.perm_ops * (32 * state_size),
    };
}

//
// =====================================================
// BENCHMARK
// =====================================================
//

fn benchmarkQubitSize(
    allocator: std.mem.Allocator,
    q: u32,
    iterations: usize,
) !BenchResult {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();

    const a = arena.allocator();

    var circuit = try buildCircuit(a, q);
    defer circuit.deinit();

    const plan = try circuit.compile(a);
    const blocks = try build_blocks(plan.ops.items, a);

    var trace = KernelTrace{};

    const total_ns = try runKernel(a, blocks, q, iterations, &trace);

    const avg_ns =
        @as(f64, @floatFromInt(total_ns)) /
        @as(f64, @floatFromInt(iterations));

    const seconds =
        @as(f64, @floatFromInt(total_ns)) / 1e9;

    const state_size = @as(u64, 1) << @intCast(q);

    const m = computeMetrics(trace, state_size);

    const flops_per_sec =
        if (seconds > 0)
            @as(f64, @floatFromInt(m.flops)) / seconds
        else
            0;

    const gb_per_sec =
        if (seconds > 0)
            (@as(f64, @floatFromInt(m.bytes)) / seconds) / 1e9
        else
            0;

    const ai =
        if (m.bytes > 0)
            @as(f64, @floatFromInt(m.flops)) /
                @as(f64, @floatFromInt(m.bytes))
        else
            0;

    const total_ops =
        trace.hadamard_ops +
        trace.zphase_ops +
        trace.perm_ops;

    const perm_ratio =
        if (total_ops > 0)
            @as(f64, @floatFromInt(trace.perm_ops)) /
                @as(f64, @floatFromInt(total_ops))
        else
            0;

    const h_ratio =
        if (total_ops > 0)
            @as(f64, @floatFromInt(trace.hadamard_ops)) /
                @as(f64, @floatFromInt(total_ops))
        else
            0;

    const z_ratio =
        if (total_ops > 0)
            @as(f64, @floatFromInt(trace.zphase_ops)) /
                @as(f64, @floatFromInt(total_ops))
        else
            0;

    return .{
        .q = q,
        .state_size = @as(usize, 1) << @intCast(q),

        .total_ns = total_ns,
        .avg_ns = avg_ns,

        .flops = m.flops,
        .bytes = m.bytes,

        .flops_per_sec = flops_per_sec,
        .gb_per_sec = gb_per_sec,
        .ai = ai,

        .perm_ratio = perm_ratio,
        .h_ratio = h_ratio,
        .z_ratio = z_ratio,

        .bottleneck = classifyAI(ai),
    };
}

//
// =====================================================
// DRIVER
// =====================================================
//

pub fn runScalingBenchmark(
    allocator: std.mem.Allocator,
    max_q: u32,
    iterations: usize,
) !void {
    std.debug.print("\n=== QUANTUM KERNEL ANALYTICS ===\n", .{});
    std.debug.print("q | state | ns | FLOPs/s | GB/s | AI | perm% | H% | Z% | class\n", .{});

    var q: u32 = 2;

    while (q <= max_q) : (q += 1) {
        const r = try benchmarkQubitSize(allocator, q, iterations);

        std.debug.print(
            "{d} | {d} | {d:.2} | {e:.3} | {e:.3} | {e:.3} | {d:.2} | {d:.2} | {d:.2} | {s}\n",
            .{
                r.q,
                r.state_size,
                r.avg_ns,
                r.flops_per_sec,
                r.gb_per_sec,
                r.ai,
                r.perm_ratio * 100.0,
                r.h_ratio * 100.0,
                r.z_ratio * 100.0,
                bottleneckStr(r.bottleneck),
            },
        );
    }
}
