const std = @import("std");
const KernelTrace = @import("../src/core/kernel_types.zig").KernelTrace;

pub const Metrics = struct {
    flops: u64,
    bytes: u64,
    ai: f64,
    gb_per_sec: f64,
    bottleneck: Bottleneck,
};

pub const Bottleneck = enum {
    compute_bound,
    transition,
    memory_bound,
};

pub fn classify(ai: f64) Bottleneck {
    if (ai > 1.0) return .compute_bound;
    if (ai > 0.1) return .transition;
    return .memory_bound;
}

pub fn compute(
    trace: KernelTrace,
    state_size: u64,
    seconds: f64,
) Metrics {
    const flops =
        trace.hadamard_ops * (8 * state_size) +
        trace.zphase_ops * (2 * state_size) +
        trace.perm_ops * (1 * state_size);

    const bytes =
        trace.hadamard_ops * (32 * state_size) +
        trace.zphase_ops * (16 * state_size) +
        trace.perm_ops * (32 * state_size);

    const ai =
        if (bytes > 0)
            @as(f64, @floatFromInt(flops)) / @as(f64, @floatFromInt(bytes))
        else
            0;

    const gb_per_sec =
        if (seconds > 0)
            (@as(f64, @floatFromInt(bytes)) / seconds) / 1e9
        else
            0;

    return .{
        .flops = flops,
        .bytes = bytes,
        .ai = ai,
        .gb_per_sec = gb_per_sec,
        .bottleneck = classify(ai),
    };
}

pub fn bottleneckStr(b: Bottleneck) []const u8 {
    return switch (b) {
        .compute_bound => "compute",
        .transition => "transition",
        .memory_bound => "memory",
    };
}
