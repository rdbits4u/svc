const std = @import("std");
const parse = @import("parse");
const hexdump = @import("hexdump");
const c = @cImport(
{
    @cInclude("libsvc.h");
});

const g_devel = false;

pub const svc_priv_t = extern struct
{
    svc: c.svc_channels_t = .{}, // must be first
    allocator: *const std.mem.Allocator,
    buf_s: [16]?*parse.parse_t = .{null} ** 16,

    //*************************************************************************
    pub fn delete(self: *svc_priv_t) void
    {
        for (self.buf_s) |s|
        {
            if (s) |as|
            {
                as.delete();
            }
        }
        self.allocator.destroy(self);
    }

    //*************************************************************************
    pub fn logln(self: *svc_priv_t, src: std.builtin.SourceLocation,
            comptime fmt: []const u8, args: anytype) !void
    {
        // check if function is assigned
        if (self.svc.log_msg) |alog_msg|
        {
            const alloc_buf = try std.fmt.allocPrint(self.allocator.*,
                    fmt, args);
            defer self.allocator.free(alloc_buf);
            const alloc1_buf = try std.fmt.allocPrintZ(self.allocator.*,
                    "{s}:{s}", .{src.fn_name, alloc_buf});
            defer self.allocator.free(alloc1_buf);
            _ = alog_msg(&self.svc, alloc1_buf.ptr);
        }
    }

    //*************************************************************************
    pub fn logln_devel(self: *svc_priv_t, src: std.builtin.SourceLocation,
            comptime fmt: []const u8, args: anytype) !void
    {
        if (g_devel)
        {
            return self.logln(src, fmt, args);
        }
    }

    //*************************************************************************
    pub fn process_slice_data(self: *svc_priv_t, channel_id: u16,
            slice: []u8) !c_int
    {
        try self.logln(@src(), "channel_id 0x{X}", .{channel_id});
        if ((channel_id < 0x03EC) or (channel_id > (0x03EC + 15)))
        {
            return 1;
        }
        const index = (channel_id - 0x03EC) & 0xF;
        const channel = &self.svc.channels[index];
        const s = try parse.create_from_slice(self.allocator, slice);
        defer s.delete();
        try s.check_rem(8);
        const len = s.in_u32_le();
        const flags = s.in_u32_le();
        if ((flags & 1 != 0) and (flags & 2 != 0)) // first and last
        {
            try s.check_rem(len);
            if (channel.channel_pdu) |achannel_pdu|
            {
                const cslice = s.in_u8_slice(len);
                return achannel_pdu(channel, channel_id,
                        cslice.ptr, @truncate(cslice.len));
            }
            try self.logln(@src(), "error, no channel assigned", .{});
            return 1;
        }
        if ((flags & 1) != 0) // first
        {
            if (self.buf_s[index]) |as|
            {
                as.delete();
                self.buf_s[index] = null;
            }
            self.buf_s[index] = try parse.create(self.allocator, len);
        }
        if (self.buf_s[index]) |as|
        {
            const rem = s.get_rem();
            try s.check_rem(rem);
            as.out_u8_slice(s.in_u8_slice(rem));
            if ((flags & 2) != 0) // last
            {
                try as.reset(0);
                if (channel.channel_pdu) |achannel_pdu|
                {
                    const cslice = as.in_u8_slice(len);
                    return achannel_pdu(channel, channel_id,
                            cslice.ptr, @truncate(cslice.len));
                }
                return 1;
            }
            return 0;
        }
        return 1;
    }

    //*************************************************************************
    pub fn send_slice_data(self: *svc_priv_t, channel_id: u16,
            slice: []u8) !c_int
    {
        if ((channel_id < 0x03EC) or (channel_id > (0x03EC + 15)))
        {
            return 1;
        }
        if (self.svc.channel_pdu) |achannel_pdu|
        {
            const total_len: u32 = @truncate(slice.len);
            var len_left = total_len;
            var flags: u32 = 1;
            var offset: usize = 0;
            while (len_left > 0)
            {
                var chunk_bytes = len_left;
                if (chunk_bytes > 1600)
                {
                    chunk_bytes = 1600;
                }
                else
                {
                    flags |= 2;
                }
                const cslice = slice[offset..offset + chunk_bytes];
                const rv = achannel_pdu(&self.svc, channel_id, total_len,
                        flags, cslice.ptr, @truncate(cslice.len));
                if (rv != 0)
                {
                    return 1;
                }
                len_left -= chunk_bytes;
                offset += chunk_bytes;
                flags = 0;
            }
            return 0;
        }
        return 1;
    }

};

//*****************************************************************************
pub fn create(allocator: *const std.mem.Allocator) !*svc_priv_t
{
    const priv: *svc_priv_t = try allocator.create(svc_priv_t);
    errdefer allocator.destroy(priv);
    priv.* = .{.allocator = allocator };
    return priv;
}
