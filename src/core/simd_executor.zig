const std = @import("std");

const StateVector = @import("state_vector.zig").StateVector;
const KernelBlock = @import("kernel_block.zig").KernelBlock;
const KernelTrace = @import("kernel_types.zig").KernelTrace;
const PermWorkspace = @import("kernel_types.zig").PermWorkspace;

// =====================================================
// SIMD + CACHE-BLOCKING CONSTANTS
// =====================================================
//
// W — native SIMD width for f64 at comptime:
//   Apple M-series (NEON 128-bit) : 2
//   x86 AVX2      (256-bit YMM)   : 4
//   x86 AVX-512   (512-bit ZMM)   : 8
//
// TILE — number of amplitudes per cache tile.
//   Each amplitude costs 2 × f64 = 16 bytes (re + im).
//   TILE = 2048  →  2048 × 16 = 32 KB per array half.
//   Two halves (a + b) = 64 KB — fits in M-series L1 (128 KB).
//   Tune down to 1024 if benchmarks show L1 pressure.
//
// LARGE_STRIDE_THRESHOLD — qubit index at which stride >= TILE/2.
//   Below this: both butterfly halves fit in one tile (small-stride path).
//   At or above: halves are in different tiles (large-stride path).
//   For TILE=2048: threshold = log2(1024) = 10.
//   At q=10, stride=1024 = TILE/2 → first qubit that needs large-stride.

const W: comptime_int = std.simd.suggestVectorLength(f64) orelse 2;
const Vec = @Vector(W, f64);

const TILE: usize = 2048;
const LARGE_STRIDE_THRESHOLD: usize = blk: {
    var v: usize = TILE / 2;
    var shift: usize = 0;
    while (v > 1) : (v >>= 1) shift += 1;
    break :blk shift;
};

// =====================================================
// MAIN EXECUTION ENTRY
// =====================================================

pub fn execute(
    state: *StateVector,
    blocks: []const KernelBlock,
    workspace: *PermWorkspace,
) void {
    for (blocks) |b| {
        switch (b.data) {
            .perm => |p| execute_perm(state, p, workspace),
            .hadamard => |h| execute_h_blocked(state, h),
            .zphase => |z| execute_z(state, z),
            .scalar => {},
        }
    }
}

// =====================================================
// HADAMARD — CACHE-BLOCKED SIMD BUTTERFLY
// =====================================================
//
// Strategy:
//
//   For each target qubit q:
//
//     if q < LARGE_STRIDE_THRESHOLD  (stride < TILE/2):
//       Both halves of every butterfly group fit inside a single
//       TILE-sized window. Iterate over tiles; within each tile
//       process all butterfly groups for this qubit. Full L1 reuse.
//
//     if q >= LARGE_STRIDE_THRESHOLD  (stride >= TILE/2):
//       The two halves are stride amplitudes apart — they live in
//       different tiles. We iterate over "tile pairs": load the
//       a-tile [tile_a, tile_a+TILE) and its partner b-tile
//       [tile_a+stride, tile_a+stride+TILE) simultaneously.
//       Both tiles fit in L1 together (2 × 32 KB = 64 KB on M-series).
//       Apply SIMD butterfly across the pair, write both back.
//
//   In both cases the inner butterfly arithmetic is the same
//   SIMD kernel: W pairs per instruction, scalar tail for remainder.

fn execute_h_blocked(state: *StateVector, h: KernelBlock.Hadamard) void {
    const len = state.len();
    const inv_scalar = 0.7071067811865475;
    const inv_vec: Vec = @splat(inv_scalar);

    for (h.targets) |q| {
        const stride = @as(usize, 1) << @intCast(q);
        const step = stride << 1; // full butterfly group width

        if (q < LARGE_STRIDE_THRESHOLD) {
            // ── SMALL-STRIDE PATH ─────────────────────────────────────────
            // stride < TILE/2: both halves fit in one tile.
            // Tile over the state vector; within each tile, sweep all
            // butterfly groups whose base falls in this tile.
            //
            // Tile boundary is aligned to `step` so we never split a group.
            // If step >= TILE we just iterate groups directly.

            if (step <= TILE) {
                // Multiple butterfly groups fit per tile.
                const tile_step = (TILE / step) * step; // floor to step multiple
                var tile_base: usize = 0;
                while (tile_base < len) : (tile_base += tile_step) {
                    const tile_end = @min(tile_base + tile_step, len);
                    var base = tile_base;
                    while (base < tile_end) : (base += step) {
                        butterfly_group_simd(state, base, stride, inv_vec, inv_scalar);
                    }
                }
            } else {
                // step > TILE but stride < TILE/2: groups are large but
                // halves are still local. Just iterate groups directly.
                var base: usize = 0;
                while (base < len) : (base += step) {
                    butterfly_group_simd(state, base, stride, inv_vec, inv_scalar);
                }
            }
        } else {
            // ── LARGE-STRIDE PATH ─────────────────────────────────────────
            // stride >= TILE/2: a-half and b-half live in different tiles.
            //
            // Outer loop: iterate butterfly groups (step = 2*stride apart).
            // Inner loop: slide a TILE-wide window across each half.
            //   a-window: [base + chunk,          base + chunk + TILE)
            //   b-window: [base + chunk + stride,  base + chunk + stride + TILE)
            //
            // Both windows together = 2*TILE*16 bytes. For TILE=2048 that
            // is 64 KB — fits in M-series L1 (128 KB unified) with room
            // for registers and stack. On x86 L1 is typically 32–48 KB;
            // set TILE=1024 if you see L1 thrashing there.

            var base: usize = 0;
            while (base < len) : (base += step) {
                var chunk: usize = 0;
                while (chunk < stride) : (chunk += TILE) {
                    const chunk_len = @min(TILE, stride - chunk);
                    const a_start = base + chunk;
                    const b_start = a_start + stride;

                    var j: usize = 0;
                    // SIMD bulk
                    while (j + W <= chunk_len) : (j += W) {
                        const a = a_start + j;
                        const b = b_start + j;
                        const ar: Vec = state.re[a..][0..W].*;
                        const ai: Vec = state.im[a..][0..W].*;
                        const br: Vec = state.re[b..][0..W].*;
                        const bi: Vec = state.im[b..][0..W].*;
                        state.re[a..][0..W].* = (ar + br) * inv_vec;
                        state.im[a..][0..W].* = (ai + bi) * inv_vec;
                        state.re[b..][0..W].* = (ar - br) * inv_vec;
                        state.im[b..][0..W].* = (ai - bi) * inv_vec;
                    }
                    // Scalar tail
                    while (j < chunk_len) : (j += 1) {
                        butterfly_scalar(state, a_start + j, b_start + j, inv_scalar);
                    }
                }
            }
        }
    }
}

// Apply SIMD butterfly to one full group [base, base+stride) vs
// [base+stride, base+step). Used by the small-stride path.
inline fn butterfly_group_simd(
    state: *StateVector,
    base: usize,
    stride: usize,
    inv_vec: Vec,
    inv_scalar: f64,
) void {
    var j: usize = 0;
    while (j + W <= stride) : (j += W) {
        const a = base + j;
        const b = a + stride;
        const ar: Vec = state.re[a..][0..W].*;
        const ai: Vec = state.im[a..][0..W].*;
        const br: Vec = state.re[b..][0..W].*;
        const bi: Vec = state.im[b..][0..W].*;
        state.re[a..][0..W].* = (ar + br) * inv_vec;
        state.im[a..][0..W].* = (ai + bi) * inv_vec;
        state.re[b..][0..W].* = (ar - br) * inv_vec;
        state.im[b..][0..W].* = (ai - bi) * inv_vec;
    }
    while (j < stride) : (j += 1) {
        butterfly_scalar(state, base + j, base + j + stride, inv_scalar);
    }
}

// Single-pair butterfly.
inline fn butterfly_scalar(
    state: *StateVector,
    a: usize,
    b: usize,
    inv: f64,
) void {
    const ar = state.re[a];
    const ai = state.im[a];
    const br = state.re[b];
    const bi = state.im[b];
    state.re[a] = (ar + br) * inv;
    state.im[a] = (ai + bi) * inv;
    state.re[b] = (ar - br) * inv;
    state.im[b] = (ai - bi) * inv;
}

// =====================================================
// Z PHASE
// =====================================================

fn execute_z(state: *StateVector, z: KernelBlock.ZPhase) void {
    const len = state.len();
    for (0..len) |i| {
        var mask: usize = 0;
        for (z.targets) |q| mask |= ((i >> @intCast(q)) & 1);
        if (mask == 1) {
            state.re[i] = -state.re[i];
            state.im[i] = -state.im[i];
        }
    }
}

// =====================================================
// PERMUTATION
// =====================================================

fn apply_perm_ops(
    i: usize,
    x_masks: []const usize,
    cnot_masks: []const KernelBlock.CNotMask,
    swap_masks: []const KernelBlock.SwapMask,
) usize {
    var j = i;
    for (x_masks) |m| {
        j ^= m;
    }
    for (cnot_masks) |mc| {
        if ((j & mc.c) != 0) j ^= mc.t;
    }
    for (swap_masks) |ms| {
        const b1 = (j & ms.m1) != 0;
        const b2 = (j & ms.m2) != 0;
        if (b1 != b2) j ^= (ms.m1 | ms.m2);
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

    if (p.perm_table) |tbl| {
        std.debug.assert(tbl.len == len);
        var i: usize = 0;
        while (i < len) : (i += 1) {
            tmp_re[tbl[i]] = state.re[i];
            tmp_im[tbl[i]] = state.im[i];
        }
    } else {
        var i: usize = 0;
        while (i < len) : (i += 1) {
            const j = apply_perm_ops(i, p.x_masks, p.cnot_masks, p.swap_masks);
            tmp_re[j] = state.re[i];
            tmp_im[j] = state.im[i];
        }
    }

    const old_re = state.re;
    const old_im = state.im;
    state.re = tmp_re[0..len];
    state.im = tmp_im[0..len];
    workspace.tmp_re = old_re;
    workspace.tmp_im = old_im;
}
