const std = @import("std");

pub const OpTag = enum {
    H,
    Z,
    CNOT,
};

pub const Op = struct {
    tag: OpTag,
    target: u32,
    control: ?u32 = null,

    pub fn format(
        self: Op,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;

        switch (self.tag) {
            .H => try writer.print("H({})", .{self.target}),
            .Z => try writer.print("Z({})", .{self.target}),
            .CNOT => try writer.print("CNOT({}, {})", .{ self.control.?, self.target }),
        }
    }
};
