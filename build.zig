const std = @import("std");

pub fn build(b: *std.Build) void
{
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    // libsvc
    const libsvc = b.addSharedLibrary(.{
        .name = "svc",
        .root_source_file = b.path("src/libsvc.zig"),
        .target = target,
        .optimize = optimize,
        .strip = true,
    });
    libsvc.linkLibC();
    libsvc.addIncludePath(b.path("../common"));
    libsvc.addIncludePath(b.path("include"));
    libsvc.root_module.addImport("parse", b.createModule(.{
        .root_source_file = b.path("../common/parse.zig"),
    }));
    libsvc.root_module.addImport("hexdump", b.createModule(.{
        .root_source_file = b.path("../common/hexdump.zig"),
    }));
    libsvc.root_module.addImport("strings", b.createModule(.{
        .root_source_file = b.path("../common/strings.zig"),
    }));
    b.installArtifact(libsvc);
}
