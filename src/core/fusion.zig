const std = @import("std");

const KernelBlock = @import("kernel_block.zig").KernelBlock;
const Op = @import("execution_plan.zig").Op;

pub fn apply_perm_ops(
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
        if ((j & mc.c) != 0) {
            j ^= mc.t;
        }
    }

    for (swap_masks) |ms| {
        const b1 = (j & ms.m1) != 0;
        const b2 = (j & ms.m2) != 0;
        if (b1 != b2) {
            j ^= (ms.m1 | ms.m2);
        }
    }
    return j;
}

fn build_perm_table(
    perm: *KernelBlock.Perm,
    num_qubits: u6,
    allocator: std.mem.Allocator,
) !void {
    const n = @as(usize, 1) << num_qubits;
    const tbl = try allocator.alloc(usize, n);
    for (0..n) |i| {
        tbl[i] = apply_perm_ops(
            i,
            perm.x_masks,
            perm.cnot_masks,
            perm.swap_masks,
        );
    }
    perm.perm_table = tbl;
}

pub fn build_blocks(
    ops: []const Op,
    num_qubits: u6,
    allocator: std.mem.Allocator,
) ![]KernelBlock {
    var blocks = std.ArrayListUnmanaged(KernelBlock){};

    var i: usize = 0;

    while (i < ops.len) {
        const start = i;
        const kind = classify(ops[i]);

        i += 1;
        while (i < ops.len and classify(ops[i]) == kind) {
            i += 1;
        }

        const slice = ops[start..i];

        var qubit_mask: usize = 0;

        const data: KernelBlock.Data = switch (kind) {
            .perm => blk: {
                var x_masks = try std.ArrayListUnmanaged(usize).initCapacity(allocator, slice.len);
                var c_masks = try std.ArrayListUnmanaged(KernelBlock.CNotMask).initCapacity(allocator, slice.len);
                var s_masks = try std.ArrayListUnmanaged(KernelBlock.SwapMask).initCapacity(allocator, slice.len);

                for (slice) |op| {
                    switch (op.gate) {
                        .X => {
                            const m = @as(usize, 1) << @intCast(op.target);
                            try x_masks.append(allocator, m);
                            qubit_mask |= m;
                        },

                        .CNOT => {
                            const c = op.control orelse unreachable;
                            const t = op.target;

                            const cm = @as(usize, 1) << @intCast(c);
                            const tm = @as(usize, 1) << @intCast(t);

                            const new_mask = KernelBlock.CNotMask{ .c = cm, .t = tm };
                            var cancelled = false;
                            for (c_masks.items, 0..) |existing, idx| {
                                if (existing.c == new_mask.c and existing.t == new_mask.t) {
                                    _ = c_masks.swapRemove(idx);
                                    cancelled = true;
                                    break;
                                }
                            }

                            if (!cancelled) try c_masks.append(allocator, new_mask);
                            qubit_mask |= cm | tm;
                        },

                        .SWAP => {
                            const a = op.target;
                            const b = op.target2 orelse unreachable;

                            const m1 = @as(usize, 1) << @intCast(a);
                            const m2 = @as(usize, 1) << @intCast(b);

                            try s_masks.append(allocator, .{ .m1 = m1, .m2 = m2 });
                            qubit_mask |= m1 | m2;
                        },

                        else => unreachable,
                    }
                }
                var perm = KernelBlock.Perm{
                    .x_masks = try x_masks.toOwnedSlice(allocator),
                    .cnot_masks = try c_masks.toOwnedSlice(allocator),
                    .swap_masks = try s_masks.toOwnedSlice(allocator),
                };
                try build_perm_table(&perm, num_qubits, allocator);
                break :blk KernelBlock.Data{ .perm = perm };
            },

            .hadamard => blk: {
                var targets = try allocator.alloc(usize, slice.len);

                for (slice, 0..) |op, idx| {
                    const t = op.target;
                    targets[idx] = t;
                    qubit_mask |= (@as(usize, 1) << @intCast(t));
                }

                break :blk KernelBlock.Data{
                    .hadamard = .{ .targets = targets },
                };
            },

            .zphase => blk: {
                var targets = try allocator.alloc(usize, slice.len);

                for (slice, 0..) |op, idx| {
                    const t = op.target;
                    targets[idx] = t;
                    qubit_mask |= (@as(usize, 1) << @intCast(t));
                }

                break :blk KernelBlock.Data{
                    .zphase = .{ .targets = targets },
                };
            },

            .scalar => KernelBlock.Data{
                .scalar = {},
            },
        };

        try blocks.append(allocator, .{
            .kind = kind,
            .qubit_mask = qubit_mask,
            .data = data,
        });
    }

    return try blocks.toOwnedSlice(allocator);
}

fn classify(op: Op) KernelBlock.Kind {
    return switch (op.gate) {
        .X, .CNOT, .SWAP => .perm,
        .H => .hadamard,
        .Z => .zphase,
        else => .scalar,
    };
}
