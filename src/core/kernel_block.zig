const std = @import("std");

pub const KernelBlock = struct {
    pub const Kind = enum {
        scalar,
        perm,
        hadamard,
        zphase,
    };

    kind: Kind,

    // =========================================================
    // METADATA
    // =========================================================
    qubit_mask: usize,

    // =========================================================
    // PAYLOAD
    // =========================================================
    data: Data,

    pub const Data = union(Kind) {
        scalar: void,
        perm: Perm,
        hadamard: Hadamard,
        zphase: ZPhase,
    };

    // =========================================================
    // PERM BLOCK (FIXED)
    // =========================================================
    pub const Perm = struct {
        x_masks: []const usize,
        cnot_masks: []const CNotMask,
        swap_masks: []const SwapMask,
        perm_table: ?[]const usize = null,
    };

    pub const CNotMask = struct {
        c: usize,
        t: usize,
    };

    pub const SwapMask = struct {
        m1: usize,
        m2: usize,
    };

    // =========================================================
    // SINGLE QUBIT
    // =========================================================
    pub const Hadamard = struct {
        targets: []const usize,
    };

    pub const ZPhase = struct {
        targets: []const usize,
    };
};
