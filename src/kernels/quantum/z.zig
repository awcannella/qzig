const std = @import("std");
const StateVector = @import("../../core/state_vector.zig").StateVector;

pub fn z_kernel(state: *StateVector, target: usize) void {
    const len = state.len();

    const stride: usize = @as(usize, 1) << @intCast(target);
    const step = stride << 1;

    var base: usize = 0;

    while (base < len) : (base += step) {
        var offset: usize = 0;

        while (offset < stride) : (offset += 1) {
            const i = base + offset + stride;

            state.re[i] *= -1;
            state.im[i] *= -1;
        }
    }
}
