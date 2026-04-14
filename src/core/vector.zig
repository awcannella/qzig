const std = @import("std");

pub fn Vector(comptime T: type) type {
    return struct {
        data: []T,
        len: usize,
        allocator: std.mem.Allocator,

        // --------------------------------
        // CORE LIFECYCLE
        // --------------------------------

        // Initialize the vector with a given capacity
        pub fn init(allocator: std.mem.Allocator, n: usize) !Vector(T) {
            return .{
                .data = try allocator.alloc(T, n),
                .allocator = allocator,
                .len = 0,
            };
        }

        // Free the underlying buffer
        pub fn deinit(self: *Vector(T)) void {
            self.allocator.free(self.data);
        }

        // --------------------------
        // HOT / KERNEL ACCESS
        // --------------------------

        // Get the current number of elements
        pub inline fn getLen(self: *Vector(T)) usize {
            return self.len;
        }

        pub fn dataSlice(self: *Vector(T)) []T {
            return self.data[0..self.len];
        }

        pub fn set(self: *Vector(T), index: usize, value: T) !void {
            self.data[index] = value;
        }

        pub inline fn atUnchecked(self: *Vector(T), index: usize) *T {
            return &self.data[index];
        }
    };
}
