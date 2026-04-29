const std = @import("std");

const Circuit = @import("core/circuit.zig").Circuit;
const build_blocks = @import("core/fusion.zig").build_blocks;
const ExecutionPlan = @import("core/execution_plan.zig").ExecutionPlan;
const execute = @import("core/executor.zig").execute;
const PermWorkspace = @import("core/executor.zig").PermWorkspace;
const StateVector = @import("core/state_vector.zig").StateVector;
const KernelBlock = @import("core/kernel_block.zig").KernelBlock;

const BenchmarkResult = struct {
    compile_ns: i128,
    fusion_ns: i128,
    execution_ns: i128,
    total_ns: i128,
};

fn buildCircuit(allocator: std.mem.Allocator) !Circuit {
    var circuit = Circuit.init(allocator);

    try circuit.add_h(0);
    try circuit.add_x(1);
    try circuit.add_cnot(0, 1);
    try circuit.add_swap(0, 1);
    try circuit.add_z(1);

    return circuit;
}

fn benchCompile(circuit: *Circuit, allocator: std.mem.Allocator) !i128 {
    const start = std.time.nanoTimestamp();

    _ = try circuit.compile(allocator);

    const end = std.time.nanoTimestamp();
    return end - start;
}

fn benchFusion(plan: ExecutionPlan, allocator: std.mem.Allocator) !i128 {
    const start = std.time.nanoTimestamp();

    const blocks = try build_blocks(plan.ops.items, allocator);
    defer allocator.free(blocks);

    const end = std.time.nanoTimestamp();
    return end - start;
}

fn benchExecution(
    blocks: []const KernelBlock,
    allocator: std.mem.Allocator,
    num_qubits: u32,
    iterations: usize,
) !i128 {
    const size = @as(usize, 1) << @as(u6, @intCast(num_qubits));

    var state = try StateVector.init_zero(allocator, num_qubits);
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
        execute(&state, blocks, &workspace);
    }

    const end = std.time.nanoTimestamp();

    return end - start;
}

fn runBenchmark(allocator: std.mem.Allocator) !BenchmarkResult {
    var circuit = try buildCircuit(allocator);
    defer circuit.deinit();

    const compile_time = try benchCompile(&circuit, allocator);

    const plan = try circuit.compile(allocator);

    const fusion_start = std.time.nanoTimestamp();
    const blocks = try build_blocks(plan.ops.items, allocator);
    const fusion_end = std.time.nanoTimestamp();

    const fusion_time = fusion_end - fusion_start;

    const exec_time = try benchExecution(blocks, allocator, 2, 1000);

    return BenchmarkResult{
        .compile_ns = compile_time,
        .fusion_ns = fusion_time,
        .execution_ns = exec_time,
        .total_ns = compile_time + fusion_time + exec_time,
    };
}

fn printResult(r: BenchmarkResult) void {
    std.debug.print("\n=== BENCHMARK RESULTS ===\n", .{});
    std.debug.print("Compile   : {} ns\n", .{r.compile_ns});
    std.debug.print("Fusion    : {} ns\n", .{r.fusion_ns});
    std.debug.print("Execution : {} ns\n", .{r.execution_ns});
    std.debug.print("TOTAL     : {} ns\n", .{r.total_ns});
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    var arena = std.heap.ArenaAllocator.init(gpa.allocator());
    defer arena.deinit();

    const allocator = arena.allocator();

    const result = try runBenchmark(allocator);

    printResult(result);
}
