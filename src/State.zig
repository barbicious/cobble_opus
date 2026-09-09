const std = @import("std");
const c = @import("c");
const Window = @import("window.zig").Window;
const Shader = @import("shader.zig").Shader;
const gfx = @import("gfx.zig");
const tile = @import("tile.zig");
const zalgebra = @import("zalgebra");
const Camera = @import("Camera.zig");
const Level = @import("level.zig").Level;
const Chunk = @import("level.zig").Chunk;

const State = @This();

camera: Camera,
shader: Shader,
level: Level,

pub fn init(allocator: std.mem.Allocator, io: std.Io) !State {
    try Window.init("Cobble Opus", 1280, 720);

    try gfx.initTextureAtlas(allocator, io);

    c.glEnable(c.GL_DEPTH_TEST);
    c.glEnable(c.GL_CULL_FACE);

    const shader: Shader = try .init(@embedFile("shaders/cube.vert"), @embedFile("shaders/cube.frag"));

    shader.bind();

    shader.setMat4("u_proj", zalgebra.perspective(60.0, 1280.0 / 720.0, 0.1, 100.0));

    return .{
        .shader = shader,
        .camera = .init(2.0, 2.0, 2.0),
        .level = try .init(allocator)
    };
}

pub fn deinit(self: *State) void {
    self.level.deinit();
    self.shader.deinit();
    Window.deinit();
}

pub fn run(self: *State, allocator: std.mem.Allocator, io: std.Io) !void {
    while (Window.isGood()) {
        if (Window.isKeyDown(c.GLFW_KEY_ESCAPE)) {
            break;
        }


        try self.level.doChunkWork(allocator, io);

        const dt = Window.deltaTime();

        const old_player_chunk_pos: Chunk.Position = .fromTilePosition(
            @trunc(self.camera.position.x()),
            @trunc(self.camera.position.y()),
            @trunc(self.camera.position.z())
        );

        self.camera.tick(dt);

        const new_player_chunk_pos: Chunk.Position = .fromTilePosition(
            @trunc(self.camera.position.x()),
            @trunc(self.camera.position.y()),
            @trunc(self.camera.position.z())
        );

        if (!old_player_chunk_pos.eql(new_player_chunk_pos)) {
            try self.level.crossBoundaries(allocator, new_player_chunk_pos);
        }

        self.shader.setMat4("u_view", self.camera.viewMatrix());

        c.glClearColor(0.3, 0.6, 0.85, 1.0);
        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);

        self.level.blit();

        Window.swapBuffers();
    }
}
