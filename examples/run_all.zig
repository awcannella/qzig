const std = @import("std");
const qzig = @import("qzig");

const streaming_h = qzig.streaming_h;
const hz_mixed = qzig.hz;
const cnot_stress = qzig.cnot;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    std.debug.print("\n=== QUANTUM BENCH SUITE ===\n", .{});

    try streaming_h.runStreamingHBenchmark(allocator, 20, 500);
    try hz_mixed.runHZBenchmark(allocator, 20, 500);
    try cnot_stress.runCNOTStressBenchmark(allocator, 20, 500);
}
