const std = @import("std");
const qzig = @import("qzig");

const Circuit = qzig.Circuit;
const Gate = qzig.Gate;

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    // 1. Create circuit
    var circuit = try Circuit.init(allocator, 10);
    defer circuit.deinit();

    // 2. Create a test gate
    const g = Gate{
        .kind = .custom_2x2,
        .target0 = 0,
    };

    // 3. Add gate
    circuit.add(g);

    // 4. Compile circuit -> ExecutionPlan
    const plan = try circuit.compile(allocator);
    defer allocator.free(plan.ops);

    // 5. Sanity check output
    std.debug.print("Compiled circuit into ExecutionPlan with {d} ops\n", .{plan.ops.len});

    std.debug.print("SUCCESS: circuit compiles into execution plan\n", .{});
}
