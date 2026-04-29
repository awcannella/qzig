const std = @import("std");

const KernelBlock = @import("kernel_block.zig").KernelBlock;
const Op = @import("execution_plan.zig").Op;

//
// =====================================================
// APPLY PERM OPS (USED ONLY FOR MASK GENERATION LOGIC)
// =====================================================
//

fn apply_perm_ops(
    i: usize,
    x_masks: []const usize,
    cnot_masks: []const KernelBlock.CNotMask,
    swap_masks: []const KernelBlock.SwapMask,
) usize {
    var j = i;

    for (x_masks) |m| j ^= m;

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

//
// =====================================================
// BUILD BLOCKS (CLEAN IR GROUPING ONLY)
// =====================================================
//

pub fn build_blocks(
    ops: []const Op,
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
        var max_qubit: u8 = 0;

        const data: KernelBlock.Data = switch (kind) {
            .perm => blk: {
                var x_masks = std.ArrayListUnmanaged(usize){};
                var c_masks = std.ArrayListUnmanaged(KernelBlock.CNotMask){};
                var s_masks = std.ArrayListUnmanaged(KernelBlock.SwapMask){};

                for (slice) |op| {
                    switch (op.gate) {
                        .X => {
                            const m = @as(usize, 1) << @intCast(op.target);
                            try x_masks.append(allocator, m);

                            qubit_mask |= m;
                            max_qubit = @max(max_qubit, @as(u8, @intCast(op.target)));
                        },

                        .CNOT => {
                            const c = op.control orelse unreachable;
                            const t = op.target;

                            const cm = @as(usize, 1) << @intCast(c);
                            const tm = @as(usize, 1) << @intCast(t);

                            try c_masks.append(allocator, .{ .c = cm, .t = tm });

                            qubit_mask |= cm | tm;
                            max_qubit = @max(max_qubit, @as(u8, @intCast(c)));
                            max_qubit = @max(max_qubit, @as(u8, @intCast(t)));
                        },

                        .SWAP => {
                            const a = op.target;
                            const b = op.target2 orelse unreachable;

                            const m1 = @as(usize, 1) << @intCast(a);
                            const m2 = @as(usize, 1) << @intCast(b);

                            try s_masks.append(allocator, .{ .m1 = m1, .m2 = m2 });

                            qubit_mask |= m1 | m2;
                            max_qubit = @max(max_qubit, @as(u8, @intCast(a)));
                            max_qubit = @max(max_qubit, @as(u8, @intCast(b)));
                        },

                        else => unreachable,
                    }
                }

                break :blk KernelBlock.Data{
                    .perm = .{
                        .x_masks = try x_masks.toOwnedSlice(allocator),
                        .cnot_masks = try c_masks.toOwnedSlice(allocator),
                        .swap_masks = try s_masks.toOwnedSlice(allocator),
                    },
                };
            },

            .hadamard => blk: {
                var targets = try allocator.alloc(usize, slice.len);

                for (slice, 0..) |op, idx| {
                    const t = op.target;
                    targets[idx] = t;

                    qubit_mask |= (@as(usize, 1) << @intCast(t));
                    max_qubit = @max(max_qubit, @as(u8, @intCast(t)));
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
                    max_qubit = @max(max_qubit, @as(u8, @intCast(t)));
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
            .max_qubit = max_qubit,
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
