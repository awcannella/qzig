const std = @import("std");
const GateType = @import("gate.zig").GateType;

// defines a single quantum instruction format (core unit of ExecutionPlan)
pub const Op = struct {
    gate: GateType, // stores the operation type (.H, .X, .CNOT, ...)
    target: usize, // stores the main quibit index
    control: ?usize = null, // optional control qubit (used for CNOT)
    target2: ?usize = null, // optional second qubit (used for SWAP)
};

// Container for compiled instructions
pub const ExecutionPlan = struct {
    allocator: std.mem.Allocator, // stores memory allocator reference
    ops: std.ArrayListUnmanaged(Op), // dynamic array of Op instructions

    // Constructs the ExecutionPlan
    pub fn init(allocator: std.mem.Allocator) ExecutionPlan {
        return .{
            .allocator = allocator, // stores allocator reference
            .ops = .{}, // creates empty list of instructions
        };
    }

    // cleanup function
    pub fn deinit(self: *ExecutionPlan) void {
        self.ops.deinit(self.allocator); // frees all memory used by ops array
    }

    // adds one instruction to the IR
    pub fn add_op(self: *ExecutionPlan, op: Op) !void {
        try self.ops.append(self.allocator, op); // allocates space if needed and sotres the Op in array
    }
};
