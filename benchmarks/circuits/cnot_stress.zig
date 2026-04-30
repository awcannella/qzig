const std = @import("std");
const qzig = @import("../../lib.zig");

const Circuit = qzig.Circuit;

pub fn build(allocator: std.mem.Allocator, n: u32) !Circuit {
    var c = Circuit.init(allocator);

    var i: u32 = 0;
    while (i < n - 1) : (i += 1) {
        try c.add_cnot(i, i + 1);
    }

    return c;
}
