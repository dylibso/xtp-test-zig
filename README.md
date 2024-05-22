# xtp-test

A Zig test framework for [xtp](https://getxtp.com) /
[Extism](https://extism.org) plugins.

## Example

```zig
const std = @import("std");
const Test = @import("xtp-test").Test;

const CountVowel = struct {
    total: u32,
    count: u32,
    vowels: []const u8,
};

export fn @"test"() i32 {
    const xtp_test = Test.init(std.heap.wasm_allocator);
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
```

## API Docs

See the [`main.zig`](/src/main.zig) file for the public API of this library.

## Usage

**1. Create a Zig project using the XTP Test library**

```sh
mkdir zig-xtp-test
cd zig-xtp-test
zig init
zig fetch --save https://github.com/dylibso/xtp-test-zig/archive/v0.0.3.tar.gz
# see the `build.zig` in this repo for examples on how to configure it
```

**2. Write your test in Zig**

```zig
const std = @import("std");
const Test = @import("xtp-test").Test;

const CountVowel = struct {
    total: u32,
    count: u32,
    vowels: []const u8,
};

// you _must_ export a single `test` function (in Zig, "test" is a keyword, so use this raw literal syntax)
export fn @"test"() i32 {
    // initialize your test to run functions in a target plugin
    const xtp_test = Test.init(std.heap.wasm_allocator);
    xtp_test.assert("this is a test", true, "Expect true == true");

    // run the "count_vowels" function in the target plugin and assert the output is as expected
    const output = xtp_test.call("count_vowels", "this is a test") catch unreachable;
    const cv = fromJson(output);
    xtp_test.assertEq("count_vowels returns expected count", cv.count, 4);

    ...
```

**3. Compile your test to .wasm:**

Ensure your `build.zig` is set up properly to compile to wasm32 `freestanding`
or `wasi`. See the
[Extism `zig-pdk` examples](https://github.com/extism/zig-pdk) or the
`build.zig` in this repository for more details.

```sh
zig build
# which should output a .wasm into zig-out/bin/
```

**4. Run the test against your plugin:** Once you have your test code as a
`.wasm` module, you can run the test against your plugin using the `xtp` CLI:

### Install `xtp`

```sh
curl https://static.dylibso.com/cli/install.sh | sudo sh
```

### Run the test suite

```sh
xtp plugin test ./plugin-*.wasm --with test.wasm --mock-host host.wasm
#               ^^^^^^^^^^^^^^^        ^^^^^^^^^             ^^^^^^^^^
#               your plugin(s)         test to run           optional mock host functions
```

**Note:** The optional mock host functions must be implemented as Extism
plugins, whose exported functions match the host function signature imported by
the plugins being tested.

## Need Help?

Please reach out via the
[`#xtp` channel on Discord](https://discord.com/channels/1011124058408112148/1220464672784908358).
