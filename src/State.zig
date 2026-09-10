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
const Ray = @import("Ray.zig");

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

    shader.setMat4("u_proj", zalgebra.perspective(60.0, 1280.0 / 720.0, 0.1, 1000.0));

    return .{
        .shader = shader,
        .camera = .init(8.0, 14.0, 8.0),
        .level = try .init(allocator)
    };
}

pub fn deinit(self: *State) void {
    self.level.deinit();
    self.shader.deinit();
    Window.deinit();
}

pub fn run(self: *State, allocator: std.mem.Allocator, io: std.Io) !void {
    var last_time: f32 = @floatCast(c.glfwGetTime());

    while (Window.isGood()) {
        if (Window.isKeyDown(c.GLFW_KEY_ESCAPE)) {
            break;
        }

        try self.level.doChunkWork(allocator, io);

        const dt = Window.deltaTime();

        if (Window.isMouseDown(c.GLFW_MOUSE_BUTTON_LEFT) and @as(f32, @floatCast(c.glfwGetTime())) - last_time > 0.2) {
            last_time = @floatCast(c.glfwGetTime());

            var ray: Ray = .init(self.camera.position, self.camera.direction);

            while (ray.distance() < 6.0) : (ray.step(0.05)) {
                const tile_x: usize = @as(usize, @trunc(ray.end.x())) % 16;
                const tile_y: usize = @as(usize, @trunc(ray.end.y())) % 16;
                const tile_z: usize = @as(usize, @trunc(ray.end.z())) % 16;

                const chunk = self.level.chunks.get(.{ .x = @trunc(ray.end.x() / 16.0), .y = @trunc(ray.end.y() / 16.0), .z = @trunc(ray.end.z() / 16.0) }).?;

                const tile_type = chunk.tileAt(tile_x, tile_y, tile_z);

                if (tile_type == .air) {
                    continue;
                }

                chunk.setTile(tile_x, tile_y, tile_z, .air);

                try self.level.generation_queue.append(allocator, chunk);

                break;
            }
        }

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
