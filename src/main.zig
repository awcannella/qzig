const std = @import("std");
const qzig = @import("root.zig"); // your library root

pub fn main() !void {
    var allocator = std.heap.page_allocator;
    std.debug.print("==== QZig Matrix Core Demo ====\n\n", .{});

    // ============================================================
    // 1. CREATE MATRICES
    // ============================================================
    std.debug.print("1. Creating matrices...\n", .{});

    var A = try qzig.Matrix.zeros(&allocator, 2, 2);
    var B = try qzig.Matrix.zeros(&allocator, 2, 2);

    // A = [1 2; 3 4]
    try A.set(0, 0, qzig.Complex{ .re = 1, .im = 0 });
    try A.set(0, 1, qzig.Complex{ .re = 2, .im = 0 });
    try A.set(1, 0, qzig.Complex{ .re = 3, .im = 0 });
    try A.set(1, 1, qzig.Complex{ .re = 4, .im = 0 });

    // B = [5 6; 7 8]
    try B.set(0, 0, qzig.Complex{ .re = 5, .im = 0 });
    try B.set(0, 1, qzig.Complex{ .re = 6, .im = 0 });
    try B.set(1, 0, qzig.Complex{ .re = 7, .im = 0 });
    try B.set(1, 1, qzig.Complex{ .re = 8, .im = 0 });

    printMatrix("Matrix A", &A);
    printMatrix("Matrix B", &B);

    // ============================================================
    // 2. ADDITION
    // ============================================================
    std.debug.print("\n2. Matrix Addition (A + B)\n", .{});
    var C = try A.add(&B, &allocator);
    printMatrix("A + B", &C);

    // Expected:
    // [6 8; 10 12]

    // ============================================================
    // 3. SUBTRACTION
    // ============================================================
    std.debug.print("\n3. Matrix Subtraction (A - B)\n", .{});
    var D = try A.sub(&B, &allocator);
    printMatrix("A - B", &D);

    // Expected:
    // [-4 -4; -4 -4]

    // ============================================================
    // 4. SCALAR MULTIPLICATION
    // ============================================================
    std.debug.print("\n4. Scalar Multiplication (A * 2)\n", .{});
    const scalar = qzig.Complex{ .re = 2, .im = 0 };
    A.scalarMul(scalar);
    printMatrix("A * 2", &A);

    // ============================================================
    // 5. MATRIX MULTIPLICATION
    // ============================================================
    std.debug.print("\n5. Matrix Multiplication (A * B)\n", .{});

    // Reset A to original values for correctness
    try A.set(0, 0, qzig.Complex{ .re = 1, .im = 0 });
    try A.set(0, 1, qzig.Complex{ .re = 2, .im = 0 });
    try A.set(1, 0, qzig.Complex{ .re = 3, .im = 0 });
    try A.set(1, 1, qzig.Complex{ .re = 4, .im = 0 });

    var E = try A.mul(&B, &allocator);
    printMatrix("A * B", &E);

    // Expected:
    // [19 22; 43 50]

    // ============================================================
    // 6. IDENTITY MATRIX TEST
    // ============================================================
    std.debug.print("\n6. Identity Matrix Test\n", .{});

    var I = try qzig.Matrix.identity(&allocator, 2);
    printMatrix("Identity Matrix I", &I);

    var F = try A.mul(&I, &allocator);
    printMatrix("A * I (should equal A)", &F);

    std.debug.print("\n==== Demo Complete ====\n", .{});
}

// ============================================================
// HELPER FUNCTION: PRINT MATRIX
// ============================================================
fn printMatrix(name: []const u8, m: *qzig.Matrix) void {
    std.debug.print("{s}:\n", .{name});

    for (0..m.rows) |i| {
        for (0..m.cols) |j| {
            const val = m.getUnchecked(i, j);
            std.debug.print("{d:.2} ", .{val.re});
        }
        std.debug.print("\n", .{});
    }
}
