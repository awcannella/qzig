const std = @import("std");
const GateType = @import("gate.zig").GateType;

pub const Op = struct {
    gate: GateType,
    target: usize,
    control: ?usize = null,
    target2: ?usize = null,
};

pub const ExecutionPlan = struct {
    allocator: std.mem.Allocator,
    ops: std.ArrayListUnmanaged(Op),

    pub fn init(allocator: std.mem.Allocator) ExecutionPlan {
        return .{
            .allocator = allocator,
            .ops = .{},
        };
    }

    pub fn deinit(self: *ExecutionPlan) void {
        self.ops.deinit(self.allocator);
    }

    pub fn add_op(self: *ExecutionPlan, op: Op) !void {
        try self.ops.append(self.allocator, op);
    }
};
