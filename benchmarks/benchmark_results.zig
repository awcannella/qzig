const std = @import("std");
const metrics = @import("metrics.zig");

pub const BenchmarkResult = struct {
    // identity
    name: []const u8,
    q: u32,
    state_size: u64,

    // raw timing
    total_ns: i128,
    iterations: usize,

    // derived
    ns_per_op: f64,
    seconds: f64,

    // kernel trace summary (optional but useful)
    hadamard_ops: u64,
    zphase_ops: u64,
    perm_ops: u64,

    // computed metrics
    metrics: metrics.Metrics,

    pub fn print(self: BenchmarkResult) void {
        std.debug.print(
            "{s} | q={d} | state={d} | ns/op={d:.2} | GB/s={d:.3} | AI={d:.3} | class={s}\n",
            .{
                self.name,
                self.q,
                self.state_size,
                self.ns_per_op,
                self.metrics.gb_per_sec,
                self.metrics.ai,
                metrics.bottleneckStr(self.metrics.bottleneck),
            },
        );
    }
};
