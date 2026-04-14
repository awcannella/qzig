const std = @import("std");

pub const Complex = struct {
    re: f64,
    im: f64,

    pub inline fn add(self: Complex, other: Complex) Complex {
        return .{
            .re = self.re + other.re,
            .im = self.im + other.im,
        };
    }

    pub inline fn mul(self: Complex, other: Complex) Complex {
        return .{
            .re = self.re * other.re - self.im * other.im,
            .im = self.re * other.im + self.im * other.re,
        };
    }

    pub inline fn conj(self: Complex) Complex {
        return .{ .re = self.re, .im = -self.im };
    }

    pub inline fn norm(self: Complex) f64 {
        return self.re * self.re + self.im * self.im;
    }

    pub inline fn abs(self: Complex) f64 {
        return @sqrt(self.norm());
    }
};
