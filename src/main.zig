const std = @import("std");
const State = @import("State.zig");

pub fn main(init: std.process.Init) !void {
    var state: State = try .init(init.arena.allocator(), init.io);
    defer state.deinit();
    state.run();
}
