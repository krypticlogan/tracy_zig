const std = @import("std");

pub fn build(b: *std.Build) void {
    // Get standard build options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const optimize_external = switch (optimize) {
        .Debug => .ReleaseFast,
        else => optimize,
    };

    // Build the disabled implementation
    const impl_disabled = b.addModule("tracy_impl_disabled", .{
        .root_source_file = b.path("src/impl_disabled.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Build the library
    const tracy = b.addModule("tracy", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    tracy.addImport("impl_disabled", impl_disabled);

    // Build the enabled implementation
    const impl_enabled = b.addModule("tracy_impl_enabled", .{
        .root_source_file = b.path("src/impl_enabled.zig"),
        .target = target,
        .optimize = optimize,
    });
    impl_enabled.addImport("tracy", tracy);

    const upstream = b.dependency("tracy", .{});
    const lib_tracy = b.addStaticLibrary(.{
        .name = "tracy",
        .target = target,
        .optimize = optimize_external,
    });
    lib_tracy.addCSourceFiles(.{
        .root = upstream.path(""),
        .files = &.{
            "public/TracyClient.cpp",
            "public/client/TracyProfiler.cpp",
        },
        .flags = &.{},
    });
    lib_tracy.root_module.addCMacro("TRACY_ENABLE", "");
    lib_tracy.addIncludePath(upstream.path("public/tracy"));
    lib_tracy.installHeader(upstream.path("public/tracy/TracyC.h"), "tracy/tracy/TracyC.h");
    const hopt: std.Build.Step.Compile.HeaderInstallation.Directory.Options = .{
        .include_extensions = &.{ ".h", ".hpp" },
    };
    lib_tracy.installHeadersDirectory(upstream.path("public/client"), "tracy/client", hopt);
    lib_tracy.installHeadersDirectory(upstream.path("public/common"), "tracy/common", hopt);
    lib_tracy.linkLibCpp();

    if (target.result.os.tag == .windows) {
        lib_tracy.linkSystemLibrary("Ws2_32");
        lib_tracy.linkSystemLibrary("dbghelp");
    }
    impl_enabled.linkLibrary(lib_tracy);
}
