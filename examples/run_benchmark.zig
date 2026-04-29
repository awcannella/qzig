const std = @import("std");
const qzig = @import("qzig");
const scaling = qzig.scaling;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    try scaling.runScalingBenchmark(
        allocator,
        14, // max qubits
        1000, // iterations
    );
}
