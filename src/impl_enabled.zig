pub const build_options = @import("build_options");
pub const c = @cImport({
    @cDefine("TRACY_ENABLE", "");
    if (build_options.on_demand) @cDefine("TRACY_ON_DEMAND", "");
    if (build_options.no_broadcast) @cDefine("TRACY_NO_BROADCAST", "");
    if (build_options.only_localhost) @cDefine("TRACY_ONLY_LOCALHOST", "");
    if (build_options.only_ipv4) @cDefine("TRACY_ONLY_IPV4", "");
    if (build_options.delayed_init) @cDefine("TRACY_DELAYED_INIT", "");
    if (build_options.manual_lifetime) @cDefine("TRACY_MANUAL_LIFETIME", "");
    if (build_options.verbose) @cDefine("TRACY_VERBOSE", "");
    if (build_options.data_port) |p| @cDefine("TRACY_DATA_PORT", p);
    if (build_options.broadcast_port) |p| @cDefine("TRACY_BROADCAST_PORT", p);
    @cInclude("tracy/tracy/TracyC.h");
});
