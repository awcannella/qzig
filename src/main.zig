const std = @import("std");

const Circuit = @import("core/circuit.zig").Circuit;
const Executor = @import("core/executor.zig");
const StateVector = @import("core/state_vector.zig").StateVector;

fn print_state(state: *StateVector, label: []const u8) void {
    std.debug.print("\n{s}:\n", .{label});

    if (state.data.len == 2) {
        std.debug.print("|0> = {d:.1} + {d:.1}i\n", .{ state.data[0].re, state.data[0].im });
        std.debug.print("|1> = {d:.1} + {d:.1}i\n", .{ state.data[1].re, state.data[1].im });
    } else if (state.data.len == 4) {
        std.debug.print("|00> = {d:.1} + {d:.1}i\n", .{ state.data[0].re, state.data[0].im });
        std.debug.print("|01> = {d:.1} + {d:.1}i\n", .{ state.data[1].re, state.data[1].im });
        std.debug.print("|10> = {d:.1} + {d:.1}i\n", .{ state.data[2].re, state.data[2].im });
        std.debug.print("|11> = {d:.1} + {d:.1}i\n", .{ state.data[3].re, state.data[3].im });
    }
}

fn set_basis_1qubit(state: *StateVector, index: usize) void {
    state.data[0] = .{ .re = 0, .im = 0 };
    state.data[1] = .{ .re = 0, .im = 0 };
    state.data[index] = .{ .re = 1, .im = 0 };
}

fn set_basis_2qubit(state: *StateVector, index: usize) void {
    for (state.data) |*a| a.* = .{ .re = 0, .im = 0 };
    state.data[index] = .{ .re = 1, .im = 0 };
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    const allocator = gpa.allocator();

    std.debug.print("\n=== CLEAN PHASE 2 GATE TESTS ===\n", .{});

    // ============================================================
    // X gate test
    // ============================================================
    {
        std.debug.print("\n--- X gate ---\n", .{});

        var circuit = Circuit.init(allocator);
        defer circuit.deinit();

        try circuit.add_x(0);

        var plan = try circuit.compile(allocator);
        defer plan.deinit();

        var state = try StateVector.init_zero(allocator, 1);
        defer state.deinit(allocator);

        set_basis_1qubit(&state, 0);

        print_state(&state, "Before X");

        Executor.execute(&state, plan);

        print_state(&state, "After X");
    }

    // ============================================================
    // Z gate test
    // ============================================================
    {
        std.debug.print("\n--- Z gate ---\n", .{});

        var circuit = Circuit.init(allocator);
        defer circuit.deinit();

        try circuit.add_z(0);

        var plan = try circuit.compile(allocator);
        defer plan.deinit();

        var state = try StateVector.init_zero(allocator, 1);
        defer state.deinit(allocator);

        set_basis_1qubit(&state, 1);

        print_state(&state, "Before Z");

        Executor.execute(&state, plan);

        print_state(&state, "After Z");
    }

    // ============================================================
    // CNOT test
    // ============================================================
    {
        std.debug.print("\n--- CNOT gate ---\n", .{});

        var circuit = Circuit.init(allocator);
        defer circuit.deinit();

        try circuit.add_cnot(0, 1);

        var plan = try circuit.compile(allocator);
        defer plan.deinit();

        var state = try StateVector.init_zero(allocator, 2);
        defer state.deinit(allocator);

        // |10>
        set_basis_2qubit(&state, 2);

        print_state(&state, "Before CNOT");

        Executor.execute(&state, plan);

        print_state(&state, "After CNOT");
    }

    // ============================================================
    // SWAP test
    // ============================================================
    {
        std.debug.print("\n--- SWAP gate ---\n", .{});

        var circuit = Circuit.init(allocator);
        defer circuit.deinit();

        try circuit.add_swap(0, 1);

        var plan = try circuit.compile(allocator);
        defer plan.deinit();

        var state = try StateVector.init_zero(allocator, 2);
        defer state.deinit(allocator);

        // |10>
        set_basis_2qubit(&state, 2);

        print_state(&state, "Before SWAP");

        Executor.execute(&state, plan);

        print_state(&state, "After SWAP");
    }

    std.debug.print("\n=== END TESTS ===\n", .{});
}
