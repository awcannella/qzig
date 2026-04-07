const std = @import("std");

pub fn Vector(comptime T: type) type {
    return struct {
        data: []T,
        capacity: usize,
        len: usize,
        allocator: *std.mem.Allocator,

        // Initialize the vector with a given capacity
        pub fn init(allocator: *std.mem.Allocator, initial_capacity: usize) !Vector(T) {
            return Vector(T){
                .data = try allocator.alloc(T, initial_capacity),
                .capacity = initial_capacity,
                .allocator = allocator,
                .len = 0,
            };
        }

        // Add an element at the end
        pub fn push(self: *Vector(T), value: T) !void {
            if (self.len == self.capacity) {
                // double capacity
                const new_capacity = if (self.capacity == 0) 1 else self.capacity * 2;
                self.data = try self.allocator.realloc(self.data, new_capacity);
                self.capacity = new_capacity;
            }
            self.data[self.len] = value;
            self.len += 1;
        }

        // Remove the last element
        pub fn pop(self: *Vector(T)) !T {
            if (self.data.len == 0) return error.Empty;
            self.len -= 1;
            return self.data[self.len];
        }

        // Get the current number of elements
        pub fn getLen(self: *Vector(T)) usize {
            return self.len;
        }

        // Free the underlying buffer
        pub fn deinit(self: *Vector(T)) void {
            if (self.capacity != 0) self.allocator.free(self.data);
            self.len = 0;
            self.capacity = 0;
        }
    };
}
