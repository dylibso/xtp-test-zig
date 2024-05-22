const std = @import("std");
const Test = @import("xtp-test").Test;

const CountVowel = struct {
    total: u32,
    count: u32,
    vowels: []const u8,
};

export fn @"test"() i32 {
    const xtp_test = Test.init(std.heap.wasm_allocator);
    const json = xtp_test.mockInputJson(CountVowel, null) catch unreachable;
    defer json.deinit();
    const input: CountVowel = json.value();
    const example = CountVowel{ .total = 2, .count = 1, .vowels = "aeiouAEIOU" };

    xtp_test.assertEq("json works (consistent .count)", input.count, example.count);
    xtp_test.assertEq("json works (consistent .total)", input.total, example.total);
    xtp_test.assert("json works (consistent .vowels)", std.mem.eql(u8, input.vowels, example.vowels), "expected count and vowels fields to match after conversion");

    return 0;
}
