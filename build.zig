const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const glfw_zig_dep = b.dependency("glfw_zig", .{
        .optimize = optimize,
        .target = target
    });

    const zstbi_dep = b.dependency("zstbi", .{
        .optimize = optimize,
        .target = target,
    });

    const zalgebra_dep = b.dependency("zalgebra", .{
        .optimize = optimize,
        .target = target,
    });

    const translate_c = b.addTranslateC(.{
        .root_source_file = b.path("src/c.h"),
        .optimize = optimize,
        .target = target,
    });

    const exe = b.addExecutable(.{
        .name = "cobble_opus",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{
                    .name = "c",
                    .module = translate_c.createModule()
                },
                .{
                    .name = "zstbi",
                    .module = zstbi_dep.module("root")
                },
                .{
                    .name = "zalgebra",
                    .module = zalgebra_dep.module("zalgebra")
                }
            },
            .link_libc = true
        }),
    });
    
    exe.root_module.linkLibrary(glfw_zig_dep.artifact("glfw"));
    exe.root_module.addIncludePath(b.path("vendor/glfw/include/"));
    exe.root_module.addIncludePath(b.path("vendor/glad/include/"));
    exe.root_module.addCSourceFile(.{ .file = b.path("vendor/glad/src/glad.c") });

    b.installArtifact(exe);

    const run_step = b.step("run", "Run the app");

    const run_cmd = b.addRunArtifact(exe);
    run_step.dependOn(&run_cmd.step);

    run_cmd.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const exe_tests = b.addTest(.{
        .root_module = exe.root_module,
    });

    const run_exe_tests = b.addRunArtifact(exe_tests);

    const test_step = b.step("test", "Run tests");
    test_step.dependOn(&run_exe_tests.step);
}
