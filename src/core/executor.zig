const std = @import("std");
const ExecutionPlan = @import("execution_plan.zig").ExecutionPlan;
const StateVector = @import("state_vector.zig").StateVector;
const Complex = @import("complex.zig").Complex;
const Op = @import("execution_plan.zig").Op;

pub fn execute(
    state: *StateVector,
    plan: ExecutionPlan,
) void {

    // Apply each operation
    for (plan.ops.items) |op| {
        apply_op(state, op);
    }
}

fn apply_op(state: *StateVector, op: Op) void {
    switch (op.gate) {
        .H => apply_h(state, op.target),
        .X => apply_x(state, op.target),
        .Z => apply_z(state, op.target),

        .CNOT => apply_cnot(state, op.control.?, op.target),

        .SWAP => apply_swap(state, op.target, op.target2.?),

        else => unreachable,
    }
}

fn apply_h(state: *StateVector, target: usize) void {
    const len = state.len();
    const stride = @as(usize, 1) << @as(u6, @intCast(target));

    const inv_sqrt2: f64 = 0.7071067811865475;

    var i: usize = 0;
    while (i < len) : (i += 1) {
        // only process when target bit is 0
        if ((i & stride) == 0) {
            const j = i | stride;

            const a = state.data[i];
            const b = state.data[j];

            // (a + b) / sqrt(2)
            state.data[i] = Complex{
                .re = (a.re + b.re) * inv_sqrt2,
                .im = (a.im + b.im) * inv_sqrt2,
            };

            // (a-b) / sqrt(2)
            state.data[j] = Complex{
                .re = (a.re - b.re) * inv_sqrt2,
                .im = (a.im - b.im) * inv_sqrt2,
            };
        }
    }
}

fn apply_x(state: *StateVector, target: usize) void {
    const len = state.len();
    const stride = @as(usize, 1) << @as(u6, @intCast(target));

    var i: usize = 0;
    while (i < len) : (i += 1) {
        if ((i & stride) == 0) {
            const j = i | stride;

            const tmp = state.data[i];
            state.data[i] = state.data[j];
            state.data[j] = tmp;
        }
    }
}

fn apply_cnot(state: *StateVector, control: usize, target: usize) void {
    const len = state.len();

    const c_mask: usize = @as(usize, 1) << @intCast(control);
    const t_mask: usize = @as(usize, 1) << @intCast(target);

    var i: usize = 0;
    while (i < len) : (i += 1) {

        // only act when control bit is 1
        if ((i & c_mask) != 0) {

            // flip target bit
            const j = i ^ t_mask;

            // avoid double-swapping
            if (i < j) {
                const tmp = state.data[i];
                state.data[i] = state.data[j];
                state.data[j] = tmp;
            }
        }
    }
}

fn apply_z(state: *StateVector, target: usize) void {
    const len = state.len();
    const mask: usize = @as(usize, 1) << @intCast(target);

    var i: usize = 0;
    while (i < len) : (i += 1) {
        if ((i & mask) != 0) {
            state.data[i].re *= -1;
            state.data[i].im *= -1;
        }
    }
}

fn apply_swap(state: *StateVector, q1: usize, q2: usize) void {
    const len = state.len();

    const m1 = @as(usize, 1) << @intCast(q1);
    const m2 = @as(usize, 1) << @intCast(q2);

    var i: usize = 0;
    while (i < len) : (i += 1) {
        const b1 = (i & m1) != 0;
        const b2 = (i & m2) != 0;

        if (b1 != b2) {
            const j =
                if (b1)
                    (i & ~m1) | m2
                else
                    (i & ~m2) | m1;

            if (i < j) {
                const tmp = state.data[i];
                state.data[i] = state.data[j];
                state.data[j] = tmp;
            }
        }
    }
}
