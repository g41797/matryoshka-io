const std = @import("std");

pub fn build(b: *std.Build) void {
    const target: std.Build.ResolvedTarget = b.standardTargetOptions(.{});
    const optimize: std.builtin.OptimizeMode = b.standardOptimizeOption(.{});

    const use_lld = target.result.os.tag != .macos and
        target.result.os.tag != .freebsd and
        target.result.os.tag != .openbsd and
        target.result.os.tag != .netbsd;

    const mod: *std.Build.Module = b.addModule("matryoshka", .{
        .root_source_file = b.path("src/matryoshka.zig"),
        .target = target,
        .optimize = optimize,
        .single_threaded = false,
    });

    const lib: *std.Build.Step.Compile = b.addLibrary(.{
        .name = "matryoshka",
        .linkage = .static,
        .root_module = mod,
        .use_llvm = true,
        .use_lld = use_lld,
    });

    b.installArtifact(lib);

    const helpers: *std.Build.Module = b.createModule(.{
        .root_source_file = b.path("helpers/helpers.zig"),
        .target = target,
        .optimize = optimize,
    });

    helpers.addImport("matryoshka", mod);

    const tmod: *std.Build.Module = b.createModule(.{
        .root_source_file = b.path("tests/matryoshka_tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const emod: *std.Build.Module = b.addModule("examples", .{
        .root_source_file = b.path("examples/examples.zig"),
        .target = target,
        .optimize = optimize,
    });

    emod.addImport("matryoshka", mod);
    emod.addImport("helpers", helpers);

    const smod: *std.Build.Module = b.addModule("stories", .{
        .root_source_file = b.path("stories/stories.zig"),
        .target = target,
        .optimize = optimize,
    });

    smod.addImport("matryoshka", mod);
    smod.addImport("helpers", helpers);

    tmod.addImport("matryoshka", mod);
    tmod.addImport("helpers", helpers);
    tmod.addImport("examples", emod);
    tmod.addImport("stories", smod);

    const lib_unit_tests: *std.Build.Step.Compile = b.addTest(.{
        .root_module = tmod,
        .use_llvm = true,
        .use_lld = use_lld,
    });

    b.installArtifact(lib_unit_tests);

    const run_lib_unit_tests: *std.Build.Step.Run = b.addRunArtifact(lib_unit_tests);

    const test_step: *std.Build.Step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_lib_unit_tests.step);

    // Documentation generation step
    const docs_step: *std.Build.Step = b.step("docs", "Generate API documentation");

    const apidocs_lib: *std.Build.Step.Compile = b.addObject(.{
        .name = "matryoshka",
        .root_module = mod,
        .use_llvm = true,
        .use_lld = use_lld,
    });

    const install_apidocs: *std.Build.Step.InstallDir = b.addInstallDirectory(.{
        .source_dir = apidocs_lib.getEmittedDocs(),
        .install_dir = .{ .custom = "../kitchen/docs" },
        .install_subdir = "apidocs",
    });

    // Doc-only module: folds stories into the examples doc target, mirroring
    // how tofu's cookbook doc target already imports mailbox. Does not affect
    // the runtime "examples" module's import graph.
    const edocsMod: *std.Build.Module = b.createModule(.{
        .root_source_file = b.path("examples/examples.zig"),
        .target = target,
        .optimize = optimize,
    });
    edocsMod.addImport("matryoshka", mod);
    edocsMod.addImport("helpers", helpers);
    edocsMod.addImport("stories", smod);

    const examplesdocs_lib: *std.Build.Step.Compile = b.addObject(.{
        .name = "examples",
        .root_module = edocsMod,
        .use_llvm = true,
        .use_lld = use_lld,
    });

    const install_examplesdocs: *std.Build.Step.InstallDir = b.addInstallDirectory(.{
        .source_dir = examplesdocs_lib.getEmittedDocs(),
        .install_dir = .{ .custom = "../kitchen/docs" },
        .install_subdir = "examplesdocs",
    });

    docs_step.dependOn(&install_apidocs.step);
    docs_step.dependOn(&install_examplesdocs.step);
}
