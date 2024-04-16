const std = @import("std");
const pdk = @import("extism-pdk");
const Plugin = pdk.Plugin;
const Memory = pdk.Memory;
const harness = @import("harness.zig");

pub const Test = struct {
    plugin: Plugin,

    pub fn init(allocator: std.mem.Allocator) Test {
        return Test{ .plugin = Plugin.init(allocator) };
    }

    // Call a function from the Extism plugin being tested, passing input and returning its output.
    pub fn call(self: Test, func_name: []const u8, input: []const u8) ![]const u8 {
        const func_mem = self.plugin.allocateBytes(func_name);
        const input_mem = self.plugin.allocateBytes(input);
        const output = harness.call(func_mem.offset, input_mem.offset);
        errdefer func_mem.free();
        errdefer input_mem.free();
        const output_mem = self.plugin.findMemory(output);
        errdefer output_mem.free();
        const buf = try self.plugin.allocator.alloc(u8, @intCast(output_mem.length));
        errdefer self.plugin.allocator.free(buf);
        output_mem.load(buf);
        return buf;
    }

    // Call a function from the Extism plugin being tested, passing input and returning the time in nanoseconds spent in the fuction.
    pub fn timeNs(self: Test, func_name: []const u8, input: []const u8) u64 {
        const func_mem = self.plugin.allocateBytes(func_name);
        const input_mem = self.plugin.allocateBytes(input);
        const ns = harness.time(func_mem.offset, input_mem.offset);
        errdefer func_mem.free();
        errdefer input_mem.free();
        return ns;
    }

    // Call a function from the Extism plugin being tested, passing input and returning the time in seconds spent in the fuction.
    pub fn timeSec(self: Test, func_name: []const u8, input: []const u8) f64 {
        return @as(f64, @floatFromInt(self.timeNs(func_name, input))) / 1e9;
    }

    // Assert that the `outcome` is true, naming the assertion with `msg`, which will be used as a label in the CLI runner.
    pub fn assert(self: Test, msg: []const u8, outcome: bool) void {
        const msg_mem = self.plugin.allocateBytes(msg);
        harness.assert(msg_mem.offset, @intFromBool(outcome));
        msg_mem.free();
    }

    // Assert that `x` and `y` are equal, naming the assertion with `msg`, which will be used as a label in the CLI runner.
    pub fn assertEq(self: Test, msg: []const u8, x: anytype, y: anytype) void {
        self.assert(msg, x == y);
    }

    // Assert that `x` and `y` are not equal, naming the assertion with `msg`, which will be used as a label in the CLI runner.
    pub fn assertNe(self: Test, msg: []const u8, x: anytype, y: anytype) void {
        self.assert(msg, x != y);
    }

    // Create a new test group. NOTE: these cannot be nested and starting a new group will end the last one
    fn startGroup(self: Test, name: []const u8) void {
        const name_mem = self.plugin.allocateBytes(name);
        harness.group(name_mem.offset);
        name_mem.free();
    }

    // Reset the loaded plugin, clearing all state.
    pub fn reset(_: Test) void {
        harness.reset();
    }

    // Create a new test group, resetting the plugin before the first test after the group is created, and after the group is closed (see `Group.close`).
    pub fn newGroup(self: Test, name: []const u8) Group {
        self.reset();
        self.startGroup(name);
        return Group{};
    }
};

pub const Group = struct {
    // Close the group, resetting the plugin.
    pub fn close(_: Group) void {
        harness.reset();
    }
};
