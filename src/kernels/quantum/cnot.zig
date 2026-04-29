const std = @import("std");
const StateVector = @import("../../core/state_vector.zig").StateVector;

pub fn cnot_kernel(state: *StateVector, control: usize, target: usize) void {
    const len = state.len();

    const c_mask = @as(usize, 1) << @intCast(control);
    const t_mask = @as(usize, 1) << @intCast(target);

    const block = t_mask << 1;

    var base: usize = 0;
    while (base < len) : (base += block) {
        var offset: usize = 0;
        while (offset < t_mask) : (offset += 1) {
            const i = base + offset;

            // only process control=1 subspace
            if ((i & c_mask) == 0) continue;

            const j = i ^ t_mask;

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
}
