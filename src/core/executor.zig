const Matrix = @import("matrix.zig").Matrix;
const Gate = @import("gate.zig").Gate;

const mul_2x2 = @import("../kernels/small/mul_2x2.zig");
const mul_4x4 = @import("../kernels/small/mul_4x4.zig");

pub fn apply_gate(
    gate: Gate,
    state: *Matrix,
    workspace: *Matrix,
) void {
    switch (gate.kind) {
        .custom_2x2 => {
            mul_2x2(
                state.data.ptr,
                gate.matrix.?.data.ptr,
                workspace.data.ptr,
            );
        },

        .custom_4x4 => {
            mul_4x4(
                state.data.ptr,
                gate.matrix.?.data.ptr,
                workspace.data.ptr,
            );
        },

        else => {
            // placeholder
        },
    }

    // swap buffers (important pattern for later)
    for (state.data, workspace.data) |*a, *b| {
        a.* = b.*;
    }
}
