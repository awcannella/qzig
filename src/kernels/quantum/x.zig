const std = @import("std");
const StateVector = @import("../../core/state_vector.zig").StateVector;

pub fn x_kernel(state: *StateVector, target: usize) void {
    const len = state.len();
    const mask = @as(usize, 1) << @intCast(target);

    var base: usize = 0;

    while (base < len) : (base += (mask << 1)) {
        var offset: usize = 0;

        while (offset < mask) : (offset += 1) {
            const i = base + offset;
            const j = i | mask;

            const tr = state.re[i];
            const ti = state.im[i];

            state.re[i] = state.re[j];
            state.im[i] = state.im[j];

            state.re[j] = tr;
            state.im[j] = ti;
        }
    }
}
