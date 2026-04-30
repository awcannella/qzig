const std = @import("std");

const StateVector = @import("../core/state_vector.zig").StateVector;
const KernelBlock = @import("../core/kernel_block.zig").KernelBlock;

const KernelTrace = @import("../core/kernel_types.zig").KernelTrace;
const PermWorkspace = @import("../core/kernel_types.zig").PermWorkspace;

//
// =====================================================
// MAIN EXECUTION ENTRY
// =====================================================
//

pub fn execute(
    state: *StateVector,
    blocks: []const KernelBlock,
    workspace: *PermWorkspace,
    trace: *KernelTrace,
) void {
    for (blocks) |b| {
        switch (b.data) {
            .perm => |p| {
                trace.perm_ops += 1;
                execute_perm(state, p, workspace);
            },

            .hadamard => |h| {
                trace.hadamard_ops += h.targets.len;
                execute_h(state, h);
            },

            .zphase => |z| {
                trace.zphase_ops += z.targets.len;
                execute_z(state, z);
            },

            .scalar => {
                trace.scalar_ops += 1;
            },
        }
    }
}

//
// =====================================================
// HADAMARD
// =====================================================
//

fn execute_h(state: *StateVector, h: KernelBlock.Hadamard) void {
    const len = state.len();
    const inv = 0.7071067811865475;

    for (h.targets) |q| {
        const stride = @as(usize, 1) << @intCast(q);
        const step = stride << 1;

        var base: usize = 0;
        while (base < len) : (base += step) {
            var j: usize = 0;
            while (j < stride) : (j += 1) {
                const a = base + j;
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
}

//
// =====================================================
// Z PHASE
// =====================================================
//

fn execute_z(state: *StateVector, z: KernelBlock.ZPhase) void {
    const len = state.len();

    var i: usize = 0;
    while (i < len) : (i += 1) {
        var flip = false;

        for (z.targets) |q| {
            if ((i & (@as(usize, 1) << @intCast(q))) != 0) {
                flip = !flip;
            }
        }

        if (flip) {
            state.re[i] = -state.re[i];
            state.im[i] = -state.im[i];
        }
    }
}

//
// =====================================================
// PERMUTATION (FIXED: NO perm_map)
// =====================================================
//

fn apply_perm_ops(
    i: usize,
    x_masks: []const usize,
    cnot_masks: []const KernelBlock.CNotMask,
    swap_masks: []const KernelBlock.SwapMask,
) usize {
    var j = i;

    // X flips
    for (x_masks) |m| {
        j ^= m;
    }

    // CNOT logic
    for (cnot_masks) |mc| {
        if ((j & mc.c) != 0) {
            j ^= mc.t;
        }
    }

    // SWAP logic
    for (swap_masks) |ms| {
        const b1 = (j & ms.m1) != 0;
        const b2 = (j & ms.m2) != 0;

        if (b1 != b2) {
            j ^= (ms.m1 | ms.m2);
        }
    }

    return j;
}

fn execute_perm(
    state: *StateVector,
    p: KernelBlock.Perm,
    workspace: *PermWorkspace,
) void {
    const len = state.len();

    const tmp_re = workspace.tmp_re;
    const tmp_im = workspace.tmp_im;

    std.debug.assert(tmp_re.len >= len);
    std.debug.assert(tmp_im.len >= len);

    var i: usize = 0;
    while (i < len) : (i += 1) {
        const j = apply_perm_ops(
            i,
            p.x_masks,
            p.cnot_masks,
            p.swap_masks,
        );

        tmp_re[j] = state.re[i];
        tmp_im[j] = state.im[i];
    }

    std.mem.copyForwards(f64, state.re, tmp_re);
    std.mem.copyForwards(f64, state.im, tmp_im);
}
