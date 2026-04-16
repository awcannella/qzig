//! By convention, root.zig is the root source file when making a library.
const std = @import("std");

// =================
// Core Structure
// =================
pub const core = struct {
    pub const Complex = @import("core/complex.zig").Complex;
    pub const Vector = @import("core/vector.zig").Vector;
    pub const Matrix = @import("core/matrix.zig").Matrix;
    pub const Gate = @import("core/gate.zig").Gate;
    pub const Circuit = @import("core/circuit.zig").Circuit;
    pub const Executor = @import("core/executor.zig");
};

pub const Complex = core.Complex;
pub const Vector = core.Vector;
pub const Matrix = core.Matrix;
pub const Gate = core.Gate;
pub const Circuit = core.Circuit;
pub const Executor = core.Executor;

// ============
// Kernels
// ============
pub const kernels = struct {
    pub const small = struct {
        pub const mul_2x2 = @import("kernels/small/mul_2x2.zig").mul_2x2;
        pub const mul_4x4 = @import("kernels/small/mul_4x4.zig").mul_4x4;
    };
};
