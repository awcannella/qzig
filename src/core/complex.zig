const std = @import("std");

pub const Complex = struct {
    re: f64,
    im: f64,

    pub fn init(re: f64, im: f64) Complex {
        return Complex{ .re = re, .im = im };
    }

    pub inline fn add(self: Complex, other: Complex) Complex {
        return Complex{
            .re = self.re + other.re,
            .im = self.im + other.im,
        };
    }

    pub inline fn mul(self: Complex, other: Complex) Complex {
        return Complex{
            .re = self.re * other.re - self.im * other.im,
            .im = self.re * other.im + self.im * other.re,
        };
    }

    pub inline fn conj(self: Complex) Complex {
        return Complex{ .re = self.re, .im = -self.im };
    }

    pub inline fn norm(self: Complex) f64 {
        return self.re * self.re + self.im * self.im;
    }

    pub inline fn abs(self: Complex) f64 {
        return @sqrt(self.norm());
    }

    pub inline fn arg(self: Complex) f64 {
        return std.math.atan2(self.im, self.re);
    }

    pub fn polar(r: f64, theta: f64) Complex {
        return .{ .re = r * std.math.cos(theta), .im = r * std.math.sin(theta) };
    }

    pub inline fn proj(self: Complex) Complex {
        if (std.math.isInf(self.re) or std.math.isInf(self.im)) {
            return Complex{ .re = std.math.inf(f64), .im = 0.0 * self.im };
        }
        return self;
    }
};
