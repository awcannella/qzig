const std = @import("std");
const Complex = @import("complex.zig").Complex;

pub const StateVector = struct {
    re: []f64,
    im: []f64,
    num_qubits: usize,

    pub fn len(self: *const StateVector) usize {
        return self.re.len;
    }

    pub fn assert_valid(self: *const StateVector) void {
        std.debug.assert(self.re.len == self.im.len);
        std.debug.assert(self.re.len == (@as(usize, 1) << @intCast(self.num_qubits)));
    }

    pub fn set_basis(self: *StateVector, index: usize) void {
        @memset(self.re, 0.0);
        @memset(self.im, 0.0);
        self.re[index] = 1.0;
    }

    pub fn init_zero(allocator: std.mem.Allocator, num_qubits: usize) !StateVector {
        if (num_qubits > 20) return error.TooManyQubits;

        const size = @as(usize, 1) << @intCast(num_qubits);

        const re = try allocator.alloc(f64, size);
        const im = try allocator.alloc(f64, size);

        @memset(re, 0.0);
        @memset(im, 0.0);

        re[0] = 1.0;

        return .{
            .re = re,
            .im = im,
            .num_qubits = num_qubits,
        };
    }

    pub fn deinit(self: *StateVector, allocator: std.mem.Allocator) void {
        allocator.free(self.re);
        allocator.free(self.im);
    }

    pub fn re_ptr(self: *StateVector) [*]f64 {
        return self.re.ptr;
    }

    pub fn im_ptr(self: *StateVector) [*]f64 {
        return self.im.ptr;
    }
};
