const std = @import("std");
const GateType = @import("gate.zig").GateType;
const ExecutionPlan = @import("execution_plan.zig").ExecutionPlan;
const Op = @import("execution_plan.zig").Op;

// Circuit is a user manipulated dynamic list of quantum gate operations (Op structs)
pub const Circuit = struct {
    ops: std.ArrayListUnmanaged(Op),
    allocator: std.mem.Allocator,

    // constructs a new empty circuit object
    pub fn init(allocator: std.mem.Allocator) Circuit {
        return .{
            .allocator = allocator,
            .ops = .{},
        };
    }

    // frees all memory owned by the circuit from init
    pub fn deinit(self: *Circuit) void {
        self.ops.deinit(self.allocator);
    }

    // Records an H gate operation applied to the target qubit
    pub fn add_h(self: *Circuit, target: usize) !void {
        try self.ops.append(self.allocator, .{
            .gate = .H,
            .target = target,
        });
    }

    // Records an X gate operation applied to the target qubit
    pub fn add_x(self: *Circuit, target: usize) !void {
        try self.ops.append(self.allocator, .{
            .gate = .X,
            .target = target,
        });
    }

    // Records a Z gate operation applied to the target qubit
    pub fn add_z(self: *Circuit, target: usize) !void {
        try self.ops.append(self.allocator, .{
            .gate = .Z,
            .target = target,
        });
    }

    // Records a CNOT operation that conditionally flips the target qubit based on the control qubit
    pub fn add_cnot(self: *Circuit, control: usize, target: usize) !void {
        try self.ops.append(self.allocator, .{
            .gate = .CNOT,
            .target = target,
            .control = control,
        });
    }

    // records the SWAP gate's operation swapping qubits a and b
    pub fn add_swap(self: *Circuit, a: usize, b: usize) !void {
        try self.ops.append(self.allocator, .{
            .gate = .SWAP,
            .target = a,
            .target2 = b,
        });
    }

    pub fn compile(self: *Circuit, allocator: std.mem.Allocator) !ExecutionPlan {
        var plan = ExecutionPlan.init(allocator);

        for (self.ops.items) |op| {
            try plan.add_op(op);
        }

        return plan;
    }
};
