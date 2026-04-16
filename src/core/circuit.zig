const std = @import("std");
const Gate = @import("gate.zig").Gate;
const ExecutionPlan = @import("execution_plan.zig").ExecutionPlan;
const Op = @import("execution_plan.zig").Op;

pub const Circuit = struct {
    gates: []Gate,
    len: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, capacity: usize) !Circuit {
        return .{
            .gates = try allocator.alloc(Gate, capacity),
            .len = 0,
            .allocator = allocator,
        };
    }

    pub fn deinit(self: *Circuit) void {
        self.allocator.free(self.gates);
    }

    pub fn add(self: *Circuit, g: Gate) void {
        self.gates[self.len] = g;
        self.len += 1;
    }

    pub fn compile(self: *Circuit, allocator: std.mem.Allocator) !ExecutionPlan {
        var ops = try allocator.alloc(Op, self.len);

        for (self.gates[0..self.len], 0..) |g, i| {
            ops[i] = try gateToOp(g);
        }

        return ExecutionPlan.init(ops);
    }

    fn gateToOp(g: Gate) !Op {
        return switch (g.kind) {
            .custom_2x2 => .{
                .mul_2x2 = .{
                    .a = g.target0,
                    .b = g.target0,
                    .out = g.target0,
                },
            },

            else => @panic("unsupported gate"),
        };
    }
};
