const std = @import("std");
const B = std.Build;

// Although this function looks imperative, note that its job is to
// declaratively construct a build graph that will be executed by an external
// runner.
pub fn build(b: *std.Build) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard optimization options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall. Here we do not
    // set a preferred release mode, allowing the user to decide how to optimize.
    const optimize = b.standardOptimizeOption(.{});

    // We will also create a module for our other entry point, 'main.zig'.
    const root_mod = b.createModule(.{
        // `root_source_file` is the Zig "entry point" of the module. If a module
        // only contains e.g. external object files, you can make this `null`.
        // In this case the main source file is merely a path, however, in more
        // complicated build scripts, this could be a generated file.
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    addDependencies(root_mod, b, target, optimize);

    {
        const exe = b.addExecutable(.{ .name = "SillyCode", .root_module = root_mod });

        b.installArtifact(exe);
        const run_cmd = b.addRunArtifact(exe);
        run_cmd.step.dependOn(b.getInstallStep());

        if (b.args) |args| run_cmd.addArgs(args);

        const run_step = b.step("run", "Run the executable");
        run_step.dependOn(&run_cmd.step);
    }

    {
        const exe_unit_tests = b.addTest(.{ .root_module = root_mod });

        const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
        const test_step = b.step("test", "Run unit tests");
        test_step.dependOn(&run_exe_unit_tests.step);
    }

    {
        const exe_check = b.addExecutable(.{ .name = "check", .root_module = root_mod });
        const tests_check = b.addTest(.{ .name = "check", .root_module = root_mod });

        const check = b.step("check", "Check if exe and tests compile");
        check.dependOn(&exe_check.step);
        check.dependOn(&tests_check.step);
    }
}

fn addDependencies(
    module: *B.Module,
    b: *B,
    target: B.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
) void {
    const zclay_dep = b.dependency("zclay", .{
        .target = target,
        .optimize = optimize,
    });
    module.addImport("zclay", zclay_dep.module("zclay"));

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    module.addImport("raylib", raylib_dep.module("raylib"));
    module.linkLibrary(raylib_dep.artifact("raylib"));
}
