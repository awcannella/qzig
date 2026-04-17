const std = @import("std");
const GateType = @import("gate.zig").GateType;
const ExecutionPlan = @import("execution_plan.zig").ExecutionPlan;
const Op = @import("execution_plan.zig").Op;

pub const Circuit = struct {
    ops: std.ArrayListUnmanaged(Op),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) Circuit {
        return .{
            .allocator = allocator,
            .ops = .{},
        };
    }

    pub fn deinit(self: *Circuit) void {
        self.ops.deinit(self.allocator);
    }

    pub fn add_h(self: *Circuit, target: usize) !void {
        try self.ops.append(self.allocator, .{
            .gate = .H,
            .target = target,
        });
    }

    pub fn add_x(self: *Circuit, target: usize) !void {
        try self.ops.append(self.allocator, .{
            .gate = .X,
            .target = target,
        });
    }

    pub fn add_z(self: *Circuit, target: usize) !void {
        try self.ops.append(self.allocator, .{
            .gate = .Z,
            .target = target,
        });
    }

    pub fn add_cnot(self: *Circuit, control: usize, target: usize) !void {
        try self.ops.append(self.allocator, .{
            .gate = .CNOT,
            .target = target,
            .control = control,
        });
    }

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
