const std = @import("std");
const svc_priv = @import("svc_priv.zig");
const c = svc_priv.c;

var g_allocator: std.mem.Allocator = std.heap.c_allocator;

// int svc_init(void);
export fn svc_init() c_int
{
    return c.LIBSVC_ERROR_NONE;
}

// int svc_deinit(void);
export fn svc_deinit() c_int
{
    return c.LIBSVC_ERROR_NONE;
}

// int svc_create(struct svc_channels_t** svc_channels);
export fn svc_create(svc_channels: ?**c.svc_channels_t) c_int
{
    // check if svc_channels is nil
    if (svc_channels) |asvc_channels|
    {
        const priv = svc_priv.svc_priv_t.create(&g_allocator) catch
                return c.LIBSVC_ERROR_MEMORY;
        asvc_channels.* = @ptrCast(priv);
        return c.LIBSVC_ERROR_NONE;
    }
    return 1;
}

// int svc_delete(struct svc_channels_t* svc_channels);
export fn svc_delete(svc_channels: ?*c.svc_channels_t) c_int
{
    // check if svc_channels is nil
    if (svc_channels) |asvc_channels|
    {
        // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
        const priv: *svc_priv.svc_priv_t = @ptrCast(asvc_channels);
        priv.delete();
    }
    return c.LIBSVC_ERROR_NONE;
}

// int svc_process_data(struct svc_channels_t* svc_channels,
//                      uint16_t channel_id,
//                      void* data, uint32_t bytes);
export fn svc_process_data(svc_channels: ?*c.svc_channels_t,
        channel_id: u16, data: ?*anyopaque, bytes: u32) c_int
{
    // check if svc_channels is nil
    if (svc_channels) |asvc_channels|
    {
        // check if data is nil
        if (data) |adata|
        {
            // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
            const priv: *svc_priv.svc_priv_t = @ptrCast(asvc_channels);
            var slice: []u8 = undefined;
            slice.ptr = @ptrCast(adata);
            slice.len = bytes;
            const rv = priv.process_slice_data(channel_id, slice);
            if (rv) |arv|
            {
                return arv;
            }
            else |err|
            {
                priv.logln(@src(), "svc_process_data err {}",
                        .{err}) catch return c.LIBSVC_ERROR_MEMORY;
                return 1;
            }
        }
    }
    return c.LIBSVC_ERROR_NONE;
}

// int svc_send_data(struct svc_channels_t* svc_channels,
//                   uint16_t channel_id,
//                   void* data, uint32_t bytes);
export fn svc_send_data(svc_channels: ?*c.svc_channels_t,
        channel_id: u16, data: ?*anyopaque, bytes: u32) c_int
{
    // check if svc_channels is nil
    if (svc_channels) |asvc_channels|
    {
        // check if data is nil
        if (data) |adata|
        {
            // cast c.svc_channels_t to svc_channels_priv.rdpc_priv_t
            const priv: *svc_priv.svc_priv_t = @ptrCast(asvc_channels);
            var slice: []u8 = undefined;
            slice.ptr = @ptrCast(adata);
            slice.len = bytes;
            const rv = priv.send_slice_data(channel_id, slice);
            if (rv) |arv|
            {
                return arv;
            }
            else |err|
            {
                priv.logln(@src(), "send_slice_data err {}",
                        .{err}) catch return c.LIBSVC_ERROR_MEMORY;
                return 1;
            }
        }
    }
    return c.LIBSVC_ERROR_NONE;
}
