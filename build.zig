const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const no_docs = b.option(bool, "no-docs", "skip installing documentation") orelse false;

    const ptk = b.dependency("parser-toolkit", .{
        .target = target,
        .optimize = optimize,
    });

    const module = b.addModule("webidl", .{
        .root_source_file = .{ .path = b.pathFromRoot("webidl.zig") },
        .imports = &.{
            .{
                .name = "parser-toolkit",
                .module = ptk.module("parser-toolkit"),
            },
        },
        .target = target,
        .optimize = optimize,
    });

    const step_test = b.step("test", "Run all unit tests");

    const unit_tests = b.addTest(.{
        .root_source_file = module.root_source_file.?,
        .target = target,
        .optimize = optimize,
    });

    unit_tests.root_module.addImport("parser-toolkit", ptk.module("parser-toolkit"));

    const run_unit_tests = b.addRunArtifact(unit_tests);
    step_test.dependOn(&run_unit_tests.step);

    if (!no_docs) {
        const docs = b.addInstallDirectory(.{
            .source_dir = unit_tests.getEmittedDocs(),
            .install_dir = .prefix,
            .install_subdir = "docs",
        });

        b.getInstallStep().dependOn(&docs.step);
    }
}
