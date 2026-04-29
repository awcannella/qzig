const std = @import("std");

pub const scaling = @import("benchmarks/scaling.zig");

// =================
// Core Benchmarking API
// =================
pub const Circuit = @import("src/core/circuit.zig").Circuit;
pub const execute = @import("src/core/executor.zig").execute;
pub const build_blocks = @import("src/core/fusion.zig").build_blocks;
pub const StateVector = @import("src/core/state_vector.zig").StateVector;
pub const KernelBlock = @import("src/core/kernel_block.zig").KernelBlock;
pub const KernelTrace = @import("src/core/kernel_types.zig").KernelTrace;
pub const PermWorkspace = @import("src/core/kernel_types.zig").PermWorkspace;

// Optional but fine:
pub const Complex = @import("src/core/complex.zig").Complex;
pub const Matrix = @import("src/core/matrix.zig").Matrix;

// =================
// Kernels (explicitly advanced)
// =================
pub const kernels = struct {
    pub const small = struct {
        pub const mul_2x2 = @import("src/kernels/small/mul_2x2.zig").mul_2x2;
        pub const mul_4x4 = @import("src/kernels/small/mul_4x4.zig").mul_4x4;
    };

    pub const quantum = struct {
        pub const h = @import("src/kernels/quantum/h.zig").h;
        pub const x = @import("src/kernels/quantum/x.zig").x;
        pub const z = @import("src/kernels/quantum/z.zig").z;
        pub const cnot = @import("src/kernels/quantum/cnot.zig").cnot;
    };
};
