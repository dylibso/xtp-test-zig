const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build) void {
    comptime {
        const current_zig = builtin.zig_version;
        const min_zig = std.SemanticVersion.parse("0.12.0-dev.2030+2ac315c24") catch unreachable;
        if (current_zig.order(min_zig) == .lt) {
            @compileError(std.fmt.comptimePrint("Your Zig version v{} does not meet the minimum build requirement of v{}", .{ current_zig, min_zig }));
        }
    }

    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{
        .default_target = .{ .abi = .musl, .os_tag = .freestanding, .cpu_arch = .wasm32 },
    });

    const pdk_module = b.dependency("extism-pdk", .{ .target = target, .optimize = optimize }).module("extism-pdk");
    const xtp_test_module = b.addModule("xtp-test", .{
        .root_source_file = .{ .path = "src/main.zig" },
    });
    xtp_test_module.addImport("extism-pdk", pdk_module);

    var basic_test = b.addExecutable(.{
        .name = "basic-test",
        .root_source_file = .{ .path = "examples/basic.zig" },
        .target = target,
        .optimize = optimize,
    });
    basic_test.rdynamic = true;
    basic_test.entry = .disabled; // or, add an empty `pub fn main() void {}` in your code
    // basic_test.root_module.addImport("extism-pdk", pdk_module);
    basic_test.root_module.addImport("xtp-test", xtp_test_module);

    b.installArtifact(basic_test);
    const basic_test_step = b.step("basic_test", "Build basic_test");
    basic_test_step.dependOn(b.getInstallStep());
}
