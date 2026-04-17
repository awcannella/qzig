const std = @import("std");
const Complex = @import("complex.zig").Complex;

pub const StateVector = struct {
    data: []Complex,
    num_qubits: usize,

    pub fn init_zero(allocator: std.mem.Allocator, num_qubits: usize) !StateVector {
        if (num_qubits > 20) return error.TooManyQubits;

        const size = @as(usize, 1) << @as(u6, @intCast(num_qubits));

        var data = try allocator.alloc(Complex, size);

        // Initialize all to 0
        for (data) |*c| {
            c.* = Complex{ .re = 0.0, .im = 0.0 };
        }

        // Set |0...0> = 1
        data[0] = Complex{ .re = 1.0, .im = 0.0 };

        return StateVector{
            .data = data,
            .num_qubits = num_qubits,
        };
    }

    pub fn deinit(self: *StateVector, allocator: std.mem.Allocator) void {
        allocator.free(self.data);
    }

    pub fn len(self: *const StateVector) usize {
        return self.data.len;
    }
};
