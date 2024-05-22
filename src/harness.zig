pub extern "xtp:test/harness" fn call(u64, u64) u64;
pub extern "xtp:test/harness" fn time(u64, u64) u64;
pub extern "xtp:test/harness" fn assert(u64, u64, u64) void;
pub extern "xtp:test/harness" fn reset() void;
pub extern "xtp:test/harness" fn group(u64) void;
pub extern "xtp:test/harness" fn mock_input() u64;
