const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{
        // IMPORTANT: makes builds match your CPU for SIMD + instruction selection
        .default_target = .{ .cpu_arch = null },
    });

    const optimize = .ReleaseFast;

    // ----------------------------
    // Core module
    // ----------------------------
    const mod = b.addModule("qzig", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
    });

    // ----------------------------
    // Executable
    // ----------------------------
    const exe = b.addExecutable(.{
        .name = "qzig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,

            .imports = &.{
                .{ .name = "qzig", .module = mod },
            },
        }),
    });

    b.installArtifact(exe);

    // ----------------------------
    // RUN STEP (optimized for benchmarks)
    // ----------------------------
    const run_step = b.step("run", "Run benchmark");

    const run_cmd = b.addRunArtifact(exe);

    // IMPORTANT: pass through CPU-native optimizations manually
    // (this is what actually matters for benchmarking fairness)
    run_cmd.setCwd(b.path("."));

    run_step.dependOn(&run_cmd.step);
    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    // ----------------------------
    // TESTS (optional but kept clean)
    // ----------------------------
    const mod_tests = b.addTest(.{
        .root_module = mod,
    });

    const run_mod_tests = b.addRunArtifact(mod_tests);

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_mod_tests.step);
    test_step.dependOn(&run_exe_tests.step);
}
