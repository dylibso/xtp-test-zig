const std = @import("std");
const Test = @import("xtp-test").Test;

const CountVowel = struct {
    total: u32,
    count: u32,
    vowels: []const u8,
};

export fn @"test"() i32 {
    const xtp_test = Test.init(std.heap.wasm_allocator);
    xtp_test.assertEq("this is a test", true, true);
    xtp_test.assertGt("gt test", 10, 1);
    xtp_test.assertGte("gte test", 10.4, 10.4);
    xtp_test.assertLt("lt test", 'Z', 'a');
    xtp_test.assertLte("lte test", 0xfeeddada, 0xfeeddada);
    const output = xtp_test.call("count_vowels", "this is a test") catch unreachable;
    const cv = fromJson(output);
    xtp_test.assertEq("count_vowels returns expected count", cv.count, 4);

    // create a group of tests inside a new scope, use defer to close the group at the end of the scope
    {
        const maintain_state_group = xtp_test.newGroup("plugin should maintain state");
        defer maintain_state_group.close();
        var accumTotal: u32 = 0;
        for (0..10) |_| {
            const loop_output = xtp_test.call("count_vowels", "this is a test") catch unreachable;
            const loop_cv = fromJson(loop_output);
            accumTotal += cv.count;
            const msg = std.fmt.allocPrint(std.heap.wasm_allocator, "count_vowels returns expected incremented total: {}", .{accumTotal}) catch unreachable;
            xtp_test.assertEq(msg, loop_cv.total, accumTotal);
        }
    }

    // create a group without a scope, and close it manually at the end of your tests
    const simple_group = xtp_test.newGroup("simple timing tests");
    const sec = xtp_test.timeSec("count_vowels", "this is a test");
    xtp_test.assertLt("it should be fast", sec, 0.5);

    const ns = xtp_test.timeNs("count_vowels", "this is a test");
    xtp_test.assertLt("it should be really fast", ns, 1e5);
    simple_group.close();

    return 0;
}

fn fromJson(json: []const u8) CountVowel {
    const cv = std.json.parseFromSlice(CountVowel, std.heap.wasm_allocator, json, .{}) catch unreachable;
    return cv.value;
}
