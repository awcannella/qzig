const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = .ReleaseFast;

    // ----------------------------
    // SINGLE SHARED LIBRARY MODULE
    // ----------------------------
    const qzig = b.addModule("qzig", .{
        .root_source_file = b.path("lib.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ----------------------------
    // EXECUTABLE (USES SAME MODULE)
    // ----------------------------
    const exe = b.addExecutable(.{
        .name = "qzig",
        .root_module = b.createModule(.{
            .root_source_file = b.path("examples/run_all.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // CRITICAL LINE (this fixes EVERYTHING)
    exe.root_module.addImport("qzig", qzig);

    b.installArtifact(exe);

    // ----------------------------
    // RUN STEP
    // ----------------------------
    const run_step = b.step("run", "Run benchmark");

    const run_cmd = b.addRunArtifact(exe);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    run_step.dependOn(&run_cmd.step);

    // ----------------------------
    // TESTS (optional but clean)
    // ----------------------------
    const qzig_tests = b.addTest(.{
        .root_module = qzig,
    });

    const run_tests = b.addRunArtifact(qzig_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_tests.step);
}
