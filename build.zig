const std = @import("std");

pub fn build(b: *std.Build) void {
    // Get standard build options
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    const optimize_external = switch (optimize) {
        .Debug => .ReleaseFast,
        else => optimize,
    };

    // Get custom build options
    const on_demand = b.option(bool, "on_demand", "") orelse false;
    const no_broadcast = b.option(bool, "no_broadcast", "") orelse false;
    const only_localhost = b.option(bool, "only_localhost", "") orelse false;
    const only_ipv4 = b.option(bool, "only_ipv4", "") orelse false;
    const delayed_init = b.option(bool, "delayed_init", "") orelse false;
    const manual_lifetime = b.option(bool, "manual_lifetime", "") orelse false;
    const verbose = b.option(bool, "verbose", "") orelse false;
    const data_port = b.option(u64, "data_port", "");
    const broadcast_port = b.option(u64, "broadcast_port", "");

    // Build the disabled implementation
    const impl_disabled = b.addModule("tracy_impl_disabled", .{
        .root_source_file = b.path("src/impl_disabled.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Build the enabled implementation
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
    lib_tracy.defineCMacro("TRACY_ENABLE", "");
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

    const impl_enabled = b.addModule("tracy_impl_enabled", .{
        .root_source_file = b.path("src/impl_enabled.zig"),
        .target = target,
        .optimize = optimize,
    });
    impl_enabled.linkLibrary(lib_tracy);

    const build_options = b.addOptions();
    build_options.addOption(bool, "on_demand", on_demand);
    build_options.addOption(bool, "no_broadcast", no_broadcast);
    build_options.addOption(bool, "only_localhost", only_localhost);
    build_options.addOption(bool, "only_ipv4", only_ipv4);
    build_options.addOption(bool, "delayed_init", delayed_init);
    build_options.addOption(bool, "manual_lifetime", manual_lifetime);
    build_options.addOption(bool, "verbose", verbose);
    build_options.addOption(?u64, "data_port", data_port);
    build_options.addOption(?u64, "broadcast_port", broadcast_port);
    impl_enabled.addOptions("build_options", build_options);

    // Build the library
    const tracy = b.addModule("tracy", .{
        .root_source_file = b.path("src/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    tracy.addImport("impl_disabled", impl_disabled);
}
