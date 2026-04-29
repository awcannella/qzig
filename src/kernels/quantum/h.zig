const std = @import("std");
const StateVector = @import("../../core/state_vector.zig").StateVector;

pub fn h_kernel(state: *StateVector, target: usize) void {
    const len = state.len();
    const stride = @as(usize, 1) << @intCast(target);
    const step = stride << 1;

    const inv = 0.7071067811865475;

    var base: usize = 0;

    while (base < len) : (base += step) {
        var i: usize = 0;

        // SIMD chunk (4-wide)
        while (i + 4 <= stride) : (i += 4) {
            const a0 = base + i;
            const b0 = a0 + stride;

            const ar: @Vector(4, f64) = state.re[a0..][0..4].*;
            const ai: @Vector(4, f64) = state.im[a0..][0..4].*;
            const br: @Vector(4, f64) = state.re[b0..][0..4].*;
            const bi: @Vector(4, f64) = state.im[b0..][0..4].*;

            const invv: @Vector(4, f64) = @splat(inv);

            state.re[a0..][0..4].* = (ar + br) * invv;
            state.im[a0..][0..4].* = (ai + bi) * invv;
            state.re[b0..][0..4].* = (ar - br) * invv;
            state.im[b0..][0..4].* = (ai - bi) * invv;
        }

        // scalar remainder
        while (i < stride) : (i += 1) {
            const a = base + i;
            const b = a + stride;

            const ar = state.re[a];
            const ai = state.im[a];
            const br = state.re[b];
            const bi = state.im[b];

            state.re[a] = (ar + br) * inv;
            state.im[a] = (ai + bi) * inv;

            state.re[b] = (ar - br) * inv;
            state.im[b] = (ai - bi) * inv;
        }
    }
}
