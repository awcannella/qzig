const Matrix = @import("matrix.zig").Matrix;

pub const GateType = enum {
    I,
    X,
    Y,
    Z,
    H,
    cnot,
    swap,
    custom_2x2,
    custom_4x4,
};

pub const Gate = struct {
    kind: GateType,

    matrix: ?*const Matrix = null,

    // qubits the gate acts on
    target0: usize,
    target1: ?usize = null,
};
