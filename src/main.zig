const std = @import("std");
const benchmark = @import("core/benchmark.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try benchmark.runScalingBenchmark(
        allocator,
        10, // max qubits
        1000, // iterations
    );
}
