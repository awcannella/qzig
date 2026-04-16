const Complex = @import("../../core/complex.zig").Complex;

pub inline fn mul_2x2(
    a: [*]const Complex,
    b: [*]const Complex,
    c: [*]Complex,
) void {
    const a00 = a[0];
    const a01 = a[1];
    const a10 = a[2];
    const a11 = a[3];

    const b00 = b[0];
    const b01 = b[1];
    const b10 = b[2];
    const b11 = b[3];

    // build c00

    var c00_re = a00.re * b00.re - a00.im * b00.im;
    var c00_im = a00.re * b00.im + a00.im * b00.re;

    c00_re += a01.re * b10.re - a01.im * b10.im;
    c00_im += a01.re * b10.im + a01.im * b10.re;

    // build c01

    var c01_re = a00.re * b01.re - a00.im * b01.im;
    var c01_im = a00.re * b01.im + a00.im * b01.re;

    c01_re += a01.re * b11.re - a01.im * b11.im;
    c01_im += a01.re * b11.im + a01.im * b11.re;

    // build c10

    var c10_re = a10.re * b00.re - a10.im * b00.im;
    var c10_im = a10.re * b00.im + a10.im * b00.re;

    c10_re += a11.re * b10.re - a11.im * b10.im;
    c10_im += a11.re * b10.im + a11.im * b10.re;

    // build c11

    var c11_re = a10.re * b01.re - a10.im * b01.im;
    var c11_im = a10.re * b01.im + a10.im * b01.re;

    c11_re += a11.re * b11.re - a11.im * b11.im;
    c11_im += a11.re * b11.im + a11.im * b11.re;

    // Store

    c[0] = .{ .re = c00_re, .im = c00_im };
    c[1] = .{ .re = c01_re, .im = c01_im };
    c[2] = .{ .re = c10_re, .im = c10_im };
    c[3] = .{ .re = c11_re, .im = c11_im };
}
