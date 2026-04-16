const Complex = @import("../../core/complex.zig").Complex;

pub inline fn mul_4x4(
    a: [*]const Complex,
    b: [*]const Complex,
    c: [*]Complex,
) void {
    inline for (0..4) |i| {
        const a0 = a[i * 4 + 0];
        const a1 = a[i * 4 + 1];
        const a2 = a[i * 4 + 2];
        const a3 = a[i * 4 + 3];

        inline for (0..4) |j| {
            const b0 = b[0 * 4 + j];
            const b1 = b[1 * 4 + j];
            const b2 = b[2 * 4 + j];
            const b3 = b[3 * 4 + j];

            var re: f64 = 0.0;
            var im: f64 = 0.0;

            // k = 0
            re += a0.re * b0.re - a0.im * b0.im;
            im += a0.re * b0.im + a0.im * b0.re;

            // k = 1
            re += a1.re * b1.re - a1.im * b1.im;
            im += a1.re * b1.im + a1.im * b1.re;

            // k = 2
            re += a2.re * b2.re - a2.im * b2.im;
            im += a2.re * b2.im + a2.im * b2.re;

            // k = 3
            re += a3.re * b3.re - a3.im * b3.im;
            im += a3.re * b3.im + a3.im * b3.re;

            c[i * 4 + j] = .{ .re = re, .im = im };
        }
    }
}
