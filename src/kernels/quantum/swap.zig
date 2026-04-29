const std = @import("std");
const StateVector = @import("../../core/state_vector.zig").StateVector;

pub fn swap_kernel(state: *StateVector, q1: usize, q2: usize) void {
    const len = state.len();

    const m1 = @as(usize, 1) << @intCast(q1);
    const m2 = @as(usize, 1) << @intCast(q2);

    var i: usize = 0;

    while (i < len) : (i += 1) {
        const b1 = (i & m1) != 0;
        const b2 = (i & m2) != 0;

        if (b1 == b2) continue;

        const j =
            if (b1)
                (i & ~m1) | m2
            else
                (i & ~m2) | m1;

        if (i < j) {
            const tr = state.re[i];
            const ti = state.im[i];

            state.re[i] = state.re[j];
            state.im[i] = state.im[j];

            state.re[j] = tr;
            state.im[j] = ti;
        }
    }
}
