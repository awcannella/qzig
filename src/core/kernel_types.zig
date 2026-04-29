const std = @import("std");

pub const KernelTrace = struct {
    scalar_ops: u64 = 0,
    hadamard_ops: u64 = 0,
    zphase_ops: u64 = 0,
    perm_ops: u64 = 0,

    scalar_bytes: u64 = 0,
    hadamard_bytes: u64 = 0,
    zphase_bytes: u64 = 0,
    perm_bytes: u64 = 0,
};

pub const PermWorkspace = struct {
    tmp_re: []f64,
    tmp_im: []f64,
};
