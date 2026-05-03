const std = @import("std");

pub const BenchmarkResult = struct {
    // identity
    name: []const u8,
    q: u32,
    state_size: u64,

    // raw timing
    total_ns: i128,

    // derived
    ns_per_op: f64,

    pub fn print(self: BenchmarkResult) void {
        std.debug.print(
            "{s} | q={d} | state={d} | ns/op={d:.2} | total_ns={d}\n",
            .{
                self.name,
                self.q,
                self.state_size,
                self.ns_per_op,
                self.total_ns,
            },
        );
    }
};
