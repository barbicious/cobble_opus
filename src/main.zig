const std = @import("std");
const State = @import("State.zig");

pub fn main(init: std.process.Init) !void {
    const allocator = init.arena.allocator();

    var state: State = try .init(allocator, init.io);
    defer state.deinit();
    try state.run(allocator, init.io);
}
