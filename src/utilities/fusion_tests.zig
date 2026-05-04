const std = @import("std");
const qzig = @import("../../lib.zig");

const KernelBlock = @import("kernel_block.zig").KernelBlock;
const Op = @import("execution_plan.zig").Op;
const build_blocks = qzig.build_blocks;

// =====================================================
// TESTS
// =====================================================
//
// Run with:  zig test src/core/fusion.zig
//
// Each test constructs an Op slice, runs build_blocks,
// and asserts the mask lists have the expected length
// and that the perm_table maps every index correctly.

const testing = std.testing;

// Helper: build a perm block from ops and return it.
fn test_perm_block(ops: []const Op, nq: u6, alloc: std.mem.Allocator) !KernelBlock.Perm {
    const blocks = try build_blocks(ops, nq, alloc);
    defer alloc.free(blocks);
    return blocks[0].data.perm;
}

// ── X cancellation ───────────────────────────────────────────────────────────

test "X pair cancels to identity" {
    const alloc = testing.allocator;
    const ops = [_]Op{
        .{ .gate = .X, .target = 0, .control = null, .target2 = null },
        .{ .gate = .X, .target = 0, .control = null, .target2 = null },
    };
    const p = try test_perm_block(&ops, 3, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    // Both X gates cancelled — mask list must be empty
    try testing.expectEqual(@as(usize, 0), p.x_masks.len);

    // perm_table must be identity: every index maps to itself
    const tbl = p.perm_table.?;
    for (tbl, 0..) |dst, src| try testing.expectEqual(src, dst);
}

test "three X gates — one remains" {
    const alloc = testing.allocator;
    const ops = [_]Op{
        .{ .gate = .X, .target = 1, .control = null, .target2 = null },
        .{ .gate = .X, .target = 1, .control = null, .target2 = null },
        .{ .gate = .X, .target = 1, .control = null, .target2 = null },
    };
    const p = try test_perm_block(&ops, 3, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    // One X remains
    try testing.expectEqual(@as(usize, 1), p.x_masks.len);
    try testing.expectEqual(@as(usize, 1) << 1, p.x_masks[0]);

    // perm_table: qubit 1 bit is flipped for every index
    const tbl = p.perm_table.?;
    for (tbl, 0..) |dst, src| {
        try testing.expectEqual(src ^ (@as(usize, 1) << 1), dst);
    }
}

// ── CNOT cancellation ────────────────────────────────────────────────────────

test "CNOT pair cancels to identity" {
    const alloc = testing.allocator;
    const ops = [_]Op{
        .{ .gate = .CNOT, .target = 1, .control = 0, .target2 = null },
        .{ .gate = .CNOT, .target = 1, .control = 0, .target2 = null },
    };
    const p = try test_perm_block(&ops, 3, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    try testing.expectEqual(@as(usize, 0), p.cnot_masks.len);

    const tbl = p.perm_table.?;
    for (tbl, 0..) |dst, src| try testing.expectEqual(src, dst);
}

test "four CNOTs cancel completely" {
    const alloc = testing.allocator;
    const ops = [_]Op{
        .{ .gate = .CNOT, .target = 2, .control = 1, .target2 = null },
        .{ .gate = .CNOT, .target = 2, .control = 1, .target2 = null },
        .{ .gate = .CNOT, .target = 2, .control = 1, .target2 = null },
        .{ .gate = .CNOT, .target = 2, .control = 1, .target2 = null },
    };
    const p = try test_perm_block(&ops, 4, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    try testing.expectEqual(@as(usize, 0), p.cnot_masks.len);

    const tbl = p.perm_table.?;
    for (tbl, 0..) |dst, src| try testing.expectEqual(src, dst);
}

test "different CNOT pairs do not cancel each other" {
    const alloc = testing.allocator;
    // CNOT(0→1) and CNOT(0→2) have same control but different targets
    const ops = [_]Op{
        .{ .gate = .CNOT, .target = 1, .control = 0, .target2 = null },
        .{ .gate = .CNOT, .target = 2, .control = 0, .target2 = null },
    };
    const p = try test_perm_block(&ops, 3, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    // Both must survive — they act on different targets
    try testing.expectEqual(@as(usize, 2), p.cnot_masks.len);
}

test "CNOT stress: 10 identical CNOTs cancel to zero" {
    const alloc = testing.allocator;
    var ops: [10]Op = undefined;
    for (&ops) |*op| {
        op.* = .{ .gate = .CNOT, .target = 3, .control = 0, .target2 = null };
    }
    const p = try test_perm_block(&ops, 4, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    // 10 = 5 pairs → all cancel
    try testing.expectEqual(@as(usize, 0), p.cnot_masks.len);
    const tbl = p.perm_table.?;
    for (tbl, 0..) |dst, src| try testing.expectEqual(src, dst);
}

test "CNOT stress: 11 identical CNOTs leave one" {
    const alloc = testing.allocator;
    var ops: [11]Op = undefined;
    for (&ops) |*op| {
        op.* = .{ .gate = .CNOT, .target = 3, .control = 0, .target2 = null };
    }
    const p = try test_perm_block(&ops, 4, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    try testing.expectEqual(@as(usize, 1), p.cnot_masks.len);
}

// ── SWAP cancellation ────────────────────────────────────────────────────────

test "SWAP pair cancels to identity" {
    const alloc = testing.allocator;
    const ops = [_]Op{
        .{ .gate = .SWAP, .target = 0, .control = null, .target2 = 2 },
        .{ .gate = .SWAP, .target = 0, .control = null, .target2 = 2 },
    };
    const p = try test_perm_block(&ops, 3, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    try testing.expectEqual(@as(usize, 0), p.swap_masks.len);
    const tbl = p.perm_table.?;
    for (tbl, 0..) |dst, src| try testing.expectEqual(src, dst);
}

test "SWAP(a,b) cancels SWAP(b,a) — reversed operand order" {
    const alloc = testing.allocator;
    const ops = [_]Op{
        .{ .gate = .SWAP, .target = 0, .control = null, .target2 = 2 },
        .{ .gate = .SWAP, .target = 2, .control = null, .target2 = 0 }, // reversed
    };
    const p = try test_perm_block(&ops, 3, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    try testing.expectEqual(@as(usize, 0), p.swap_masks.len);
    const tbl = p.perm_table.?;
    for (tbl, 0..) |dst, src| try testing.expectEqual(src, dst);
}

// ── Mixed cancellation ───────────────────────────────────────────────────────

test "mixed X + CNOT + SWAP — independent cancellations" {
    const alloc = testing.allocator;
    const ops = [_]Op{
        .{ .gate = .X, .target = 0, .control = null, .target2 = null },
        .{ .gate = .CNOT, .target = 2, .control = 1, .target2 = null },
        .{ .gate = .SWAP, .target = 0, .control = null, .target2 = 3 },
        .{ .gate = .X, .target = 0, .control = null, .target2 = null }, // cancels first X
        .{ .gate = .CNOT, .target = 2, .control = 1, .target2 = null }, // cancels first CNOT
        .{ .gate = .SWAP, .target = 0, .control = null, .target2 = 3 }, // cancels first SWAP
    };
    const p = try test_perm_block(&ops, 4, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    // All three pairs cancelled
    try testing.expectEqual(@as(usize, 0), p.x_masks.len);
    try testing.expectEqual(@as(usize, 0), p.cnot_masks.len);
    try testing.expectEqual(@as(usize, 0), p.swap_masks.len);

    // perm_table is identity
    const tbl = p.perm_table.?;
    for (tbl, 0..) |dst, src| try testing.expectEqual(src, dst);
}

test "perm_table is correct after partial cancellation" {
    const alloc = testing.allocator;
    // Two CNOTs cancel, one X survives on qubit 0
    const ops = [_]Op{
        .{ .gate = .X, .target = 0, .control = null, .target2 = null },
        .{ .gate = .CNOT, .target = 1, .control = 0, .target2 = null },
        .{ .gate = .CNOT, .target = 1, .control = 0, .target2 = null }, // cancels above CNOT
    };
    const p = try test_perm_block(&ops, 3, alloc);
    defer {
        alloc.free(p.x_masks);
        alloc.free(p.cnot_masks);
        alloc.free(p.swap_masks);
        if (p.perm_table) |t| alloc.free(t);
    }

    try testing.expectEqual(@as(usize, 1), p.x_masks.len); // X survived
    try testing.expectEqual(@as(usize, 0), p.cnot_masks.len); // CNOT pair gone

    // perm_table: only qubit 0 bit is flipped (X on qubit 0)
    const tbl = p.perm_table.?;
    for (tbl, 0..) |dst, src| {
        try testing.expectEqual(src ^ @as(usize, 1), dst);
    }
}
