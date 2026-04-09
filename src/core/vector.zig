const std = @import("std");

pub fn Vector(comptime T: type) type {
    return struct {
        data: []T,
        capacity: usize,
        len: usize,
        allocator: *std.mem.Allocator,

        // --------------------------------
        // Constructors / Destructors
        // --------------------------------

        // Initialize the vector with a given capacity
        pub fn init(allocator: *std.mem.Allocator, initial_capacity: usize) !Vector(T) {
            return Vector(T){
                .data = try allocator.alloc(T, initial_capacity),
                .capacity = initial_capacity,
                .allocator = allocator,
                .len = 0,
            };
        }

        // Free the underlying buffer
        pub fn deinit(self: *Vector(T)) void {
            if (self.capacity != 0) self.allocator.free(self.data);
            self.len = 0;
            self.capacity = 0;
        }

        // --------------------------
        // Basic Accessors
        // --------------------------

        // Get the current number of elements
        pub fn getLen(self: *Vector(T)) usize {
            return self.len;
        }

        pub fn getCapacity(self: *Vector(T)) usize {
            return self.capacity;
        }

        pub fn isEmpty(self: *Vector(T)) bool {
            return self.len == 0;
        }

        pub fn dataSlice(self: *Vector(T)) []T {
            return self.data[0..self.len];
        }

        pub fn front(self: *Vector(T)) T {
            return self.data[0];
        }

        pub fn back(self: *Vector(T)) T {
            return self.data[self.len - 1];
        }

        // ---------------------------
        // Modifiers
        // ---------------------------

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
            if (self.len == 0) return error.Empty;
            self.len -= 1;
            return self.data[self.len];
        }

        pub fn clear(self: *Vector(T)) void {
            self.len = 0;
        }

        pub fn reserve(self: *Vector(T), new_capacity: usize) !void {
            if (new_capacity <= self.capacity) return;
            self.data = try self.allocator.realloc(self.data, self.len);
            self.capacity = self.len;
        }

        pub fn resize(self: *Vector(T), new_len: usize, default_value: T) !void {
            if (new_len > self.capacity) try self.reserve(new_len);
            if (new_len > self.len) {
                // initialize new elements with default_value
                for (self.len..new_len) |i| {
                    self.data[i] = default_value;
                }
            }
            self.len = new_len;
        }

        // ---------------------------------
        // Element Access
        // ---------------------------------

        pub fn at(self: *Vector(T), index: usize) !T {
            if (index >= self.len) return error.OutOfBounds;
            return self.data[index];
        }

        pub fn set(self: *Vector(T), index: usize, value: T) !void {
            if (index >= self.len) return error.OutOfBounds;
            self.data[index] = value;
        }

        pub fn atUnchecked(self: *Vector(T), index: usize) *T {
            return &self.data[index];
        }

        // --------------------------
        // Swap / Assign
        // --------------------------

        pub fn swap(self: *Vector(T), other: *Vector(T)) !void {
            if (self.len != other.len) return error.LengthMismatch;
            for (0..self.len) |i| {
                const tmp = self.data[i];
                self.data[i] = other.data[i];
                other.data[i] = tmp;
            }
        }

        pub fn assign(self: *Vector(T), other: *Vector(T)) !void {
            try self.resize(other.len, undefined);
            for (0..other.len) |i| {
                self.data[i] = other.data[i];
            }
        }
    };
}
