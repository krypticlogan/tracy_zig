const tracy = @import("tracy");
pub const c = @cImport({
    @cDefine("TRACY_ENABLE", "");
    if (tracy.options.on_demand) @cDefine("TRACY_ON_DEMAND", "");
    if (tracy.options.no_broadcast) @cDefine("TRACY_NO_BROADCAST", "");
    if (tracy.options.only_localhost) @cDefine("TRACY_ONLY_LOCALHOST", "");
    if (tracy.options.only_ipv4) @cDefine("TRACY_ONLY_IPV4", "");
    if (tracy.options.delayed_init) @cDefine("TRACY_DELAYED_INIT", "");
    if (tracy.options.manual_lifetime) @cDefine("TRACY_MANUAL_LIFETIME", "");
    if (tracy.options.verbose) @cDefine("TRACY_VERBOSE", "");
    if (tracy.options.data_port) |p| @cDefine("TRACY_DATA_PORT", p);
    if (tracy.options.broadcast_port) |p| @cDefine("TRACY_BROADCAST_PORT", p);
    @cInclude("tracy/tracy/TracyC.h");
});
