const std = @import("std");
const Complex = @import("complex.zig").Complex;

pub const Op = union(enum) {
    mul_2x2: struct {
        a: usize,
        b: usize,
        out: usize,
    },

    mul_4x4: struct {
        a: usize,
        b: usize,
        out: usize,
    },

    gemm_small: struct {
        m: usize,
        n: usize,
        k: usize,
    },
};

pub const ExecutionPlan = struct {
    ops: []Op,

    pub fn init(ops: []Op) ExecutionPlan {
        return .{ .ops = ops };
    }
};
