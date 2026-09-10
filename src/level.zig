const tile = @import("tile.zig");
const c = @import("c");
const std = @import("std");
const fastnoise = @import("fastnoise.zig");

const noise: fastnoise.Noise(f32) = .{
    .seed = 1337,
    .noise_type = .cellular,
    .frequency = 0.05,
    .gain = 0.40,
    .fractal_type = .fbm,
    .lacunarity = 0.80,
    .cellular_distance = .euclidean,
    .cellular_return = .distance2,
    .cellular_jitter_mod = 0.88,
};

pub const Chunk = struct {
    pub const Position = struct {
        x: i32,
        y: i32,
        z: i32,

        pub fn fromTilePosition(x: i32, y: i32, z: i32) Position {
            return .{
                .x = @divTrunc(x, @as(i32, @intCast(width))),
                .y = @divTrunc(y, @as(i32, @intCast(height))),
                .z = @divTrunc(z, @as(i32, @intCast(depth))),
            };
        }

        pub fn eql(self: Position, other: Position) bool {
            return self.x == other.x and self.y == other.y and self.z == other.z;
        }
    };
    
    pub const Mesh = struct {
        chunk: *const Chunk,
        vertices: std.ArrayList(f32),
        vao: u32,
        vbo: u32,

        pub fn init(chunk: *const Chunk) Mesh {
            var vao: u32 = 0;
            c.glGenVertexArrays(1, &vao);
            c.glBindVertexArray(vao);

            var vbo: u32 = 0;
            c.glGenBuffers(1, &vbo);
            c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);

            c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(f32) * (width * height * depth) * 216, null, c.GL_STREAM_DRAW);

            c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(0));
            c.glEnableVertexAttribArray(0);
            c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
            c.glEnableVertexAttribArray(1);
            c.glVertexAttribPointer(2, 1, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(5 * @sizeOf(f32)));
            c.glEnableVertexAttribArray(2);

            return .{
                .chunk = chunk,
                .vertices = .empty,
                .vao = vao,
                .vbo = vbo,
            };
        }

        pub fn deinit(self: *Mesh) void {
            c.glDeleteBuffers(1, &self.vbo);
            c.glDeleteVertexArrays(1, &self.vao);
        }

        pub fn generate(self: *Mesh, allocator: std.mem.Allocator, level: *const Level) !void {
            self.vertices.clearRetainingCapacity();

            const left_chunk = level.chunks.get(self.chunk.relativePosition(-1, 0, 0));
            const right_chunk = level.chunks.get(self.chunk.relativePosition(1, 0, 0));

            const down_chunk = level.chunks.get(self.chunk.relativePosition(0, -1, 0));
            const up_chunk = level.chunks.get(self.chunk.relativePosition(0, 1, 0));

            const front_chunk = level.chunks.get(self.chunk.relativePosition(0, 0, -1));
            const back_chunk = level.chunks.get(self.chunk.relativePosition(0, 0, 1));

            for (0..self.chunk.tiles.len) |tile_idx| {
                const x = tile_idx % width;
                const y = (tile_idx / width) % height;
                const z = tile_idx / (width * height);

                const tile_type = self.chunk.tiles[tile_idx];

                if (tile_type == .air) {
                    continue;
                }
                
                const world_x = @as(f32, @floatFromInt(x)) + (@as(f32, @floatFromInt(width)) * @as(f32, @floatFromInt(self.chunk.position.x)));
                const world_y = @as(f32, @floatFromInt(y)) + (@as(f32, @floatFromInt(height)) * @as(f32, @floatFromInt(self.chunk.position.y)));
                const world_z = @as(f32, @floatFromInt(z)) + (@as(f32, @floatFromInt(depth)) * @as(f32, @floatFromInt(self.chunk.position.z)));

                if (x > 0) {
                    if (self.chunk.isTileTransluscent(x - 1, y, z)) {
                        try self.addFace(tile_type, .left, world_x, world_y, world_z, allocator);
                    }
                } else if (left_chunk) |left_c| {
                    if (left_c.isTileTransluscent(width - 1, y, z)) {
                        try self.addFace(tile_type, .left, world_x, world_y, world_z, allocator);
                    }
                }

                if (x < width - 1) {
                    if (self.chunk.isTileTransluscent(x + 1, y, z)) {
                        try self.addFace(tile_type, .right, world_x, world_y, world_z, allocator);
                    }
                } else if (right_chunk) |right_c| {
                    if (right_c.isTileTransluscent(0, y, z)) {
                        try self.addFace(tile_type, .right, world_x, world_y, world_z, allocator);
                    }
                }

                if (y > 0) {
                    if (self.chunk.isTileTransluscent(x, y - 1, z)) {
                        try self.addFace(tile_type, .bottom, world_x, world_y, world_z, allocator);
                    }
                } else if (down_chunk) |down_c| {
                    if (down_c.isTileTransluscent(x, height - 1, z)) {
                        try self.addFace(tile_type, .bottom, world_x, world_y, world_z, allocator);
                    }
                }

                if (y < height - 1) {
                    if (self.chunk.isTileTransluscent(x, y + 1, z)) {
                        try self.addFace(tile_type, .top, world_x, world_y, world_z, allocator);
                    }
                } else if (up_chunk) |up_c| {
                    if (up_c.isTileTransluscent(x, 0, z)) {
                        try self.addFace(tile_type, .top, world_x, world_y, world_z, allocator);
                    }
                }

                if (z > 0) {
                    if (self.chunk.isTileTransluscent(x, y, z - 1)) {
                        try self.addFace(tile_type, .front, world_x, world_y, world_z, allocator);
                    }
                } else if (front_chunk) |front_c| {
                    if (front_c.isTileTransluscent(x, y, depth - 1)) {
                        try self.addFace(tile_type, .front, world_x, world_y, world_z, allocator);
                    }
                }

                if (z < depth - 1) {
                    if (self.chunk.isTileTransluscent(x, y, z + 1)) {
                        try self.addFace(tile_type, .back, world_x, world_y, world_z, allocator);
                    }
                } else if (back_chunk) |back_c| {
                    if (back_c.isTileTransluscent(x, y, 0)) {
                        try self.addFace(tile_type, .back, world_x, world_y, world_z, allocator);
                    }
                }
            }
        }

        pub fn upload(self: *const Mesh) void {
            c.glBindVertexArray(self.vao);
            c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);

            c.glBufferSubData(
                c.GL_ARRAY_BUFFER,
                0,
                @sizeOf(f32) * @as(i64, @intCast(self.vertices.items.len)),
                self.vertices.items.ptr,
            );
        }

        pub fn addFace(self: *Mesh, tile_type: tile.Tile, face: tile.Face, x: f32, y: f32, z: f32, allocator: std.mem.Allocator) !void {
            const tile_vertices = tile.vertices(tile_type, face, (x), (y), (z));
            try self.vertices.appendSlice(allocator, tile_vertices[0..]);
        }

        pub fn blit(self: *Mesh) void {
            c.glBindVertexArray(self.vao);
            c.glBindBuffer(c.GL_ARRAY_BUFFER, self.vbo);

            c.glDrawArrays(c.GL_TRIANGLES, 0, @as(i32, @intCast(@divTrunc(self.vertices.items.len, 6))));
        }
    };

    const width: u32 = 16;
    const height: u32 = 16;
    const depth: u32 = 16;

    tiles: [width * height * depth]tile.Tile,
    position: Position,
    mesh: Mesh,
    flags: struct {
        dirty: bool
    },

    pub fn init(chunk: *Chunk, position: Position) void {
        const tiles: [width * height * depth]tile.Tile = [_]tile.Tile{ .air } ** (width * height * depth);

        chunk.tiles = tiles;
        chunk.position = position;
        chunk.mesh = .init(chunk);
    }

    pub fn generateTerrain(self: *Chunk) void {
        for (0..self.tiles.len) |tile_idx| {
            const x = tile_idx % width;
            const y = (tile_idx / width) % height;
            const z = tile_idx / (width * height);

            const world_z = @as(i32, @intCast(z)) + self.position.z * depth;
            const world_x = @as(i32, @intCast(x)) + self.position.x * width;
            const world_y = @as(i32, @intCast(y)) + self.position.y * height;

            const value: i32 = @intFromFloat((noise.genNoise2D(@floatFromInt(world_x), @floatFromInt(world_z)) + 1.0) * 16.0 + @as(f32, @floatFromInt(world_y)));

            if (value == 19) {
                self.setTile(x, y, z, .grass);
            } else if (value < 19) {
                self.setTile(x, y, z, .cobblestone);
            }
        }
    }

    pub inline fn idx(x: usize, y: usize, z: usize) usize {
        return x + width * (y + height * z);
    }

    pub inline fn tileAt(self: *const Chunk, x: usize, y: usize, z: usize) tile.Tile {
        return self.tiles[Chunk.idx(x, y, z)];
    }

    pub inline fn setTile(self: *Chunk, x: usize, y: usize, z: usize, placed_tile: tile.Tile) void {
        self.tiles[Chunk.idx(x, y, z)] = placed_tile;
    }

    pub inline fn isTileTransluscent(self: *const Chunk, x: usize, y: usize, z: usize) bool {
        return self.tileAt(x, y, z) == .air;
    }

    inline fn relativePosition(self: *const Chunk, ox: i32, oy: i32, oz: i32) Position {
        return .{
            .x = self.position.x + ox,
            .y = self.position.y + oy,
            .z = self.position.z + oz
        };
    }
};

pub const Level = struct {
    const render_distance: i8 = 5;
    
    chunks: std.AutoHashMap(Chunk.Position, *Chunk),
    generation_queue: std.ArrayList(*Chunk),
    
    pub fn init(allocator: std.mem.Allocator) !Level {
        var chunks: std.AutoHashMap(Chunk.Position, *Chunk) = .init(allocator);
        var generation_queue: std.ArrayList(*Chunk) = .empty;

        var z: i8 = -render_distance;
        while (z <= render_distance) : (z += 1) {
            var x: i8 = -render_distance;
            while (x <= render_distance) : (x += 1) {
                var y: i8 = -render_distance;
                while (y <= render_distance) : (y += 1) {
                    const chunk = try allocator.create(Chunk);
                    Chunk.init(chunk, .{ .x = x, .y = y, .z = z });
                    try chunks.put(chunk.position, chunk);
                    try generation_queue.append(allocator, chunk);
                }
            }
        }

        return .{
            .chunks = chunks,
            .generation_queue = generation_queue,
        };
    }

    pub fn deinit(self: *Level) void {
        self.chunks.deinit();
    }

    pub fn crossBoundaries(self: *Level, allocator: std.mem.Allocator, player_pos: Chunk.Position) !void {
        {
            var iter = self.chunks.valueIterator();

            while (iter.next()) |chunk| {
                chunk.*.flags.dirty = true;
            }
        }

        var z: i32 = -render_distance + player_pos.z;
        while (z <= render_distance + player_pos.z) : (z += 1) {

            var x: i32 = -render_distance + player_pos.x;
            while (x <= render_distance + player_pos.x) : (x += 1) {

                var y: i32 = -render_distance + player_pos.y;
                while (y <= render_distance + player_pos.y) : (y += 1) {

                    const chunk_pos: Chunk.Position = .{ .x = x, .y = y, .z = z };

                    if (self.chunks.get(chunk_pos)) |chunk| {
                        chunk.flags.dirty = false;
                    } else {
                        const chunk = try allocator.create(Chunk);
                        Chunk.init(chunk, .{ .x = x, .y = y, .z = z });
                        try self.chunks.put(chunk.position, chunk);
                        try self.generation_queue.append(allocator, chunk);
                    }
                }
            }
        }

        {
            var iter = self.chunks.valueIterator();

            while (iter.next()) |chunk| {
                if (chunk.*.flags.dirty) {
                    _ = self.chunks.remove(chunk.*.position);
                }
            }
        }
    }
    pub fn doChunkWork(self: *Level, allocator: std.mem.Allocator, io: std.Io) !void {
        var meshes_to_generate: std.ArrayList(*Chunk.Mesh) = .empty;

        if (self.generation_queue.items.len > 0) {
            var g: std.Io.Group = .init;

            errdefer g.cancel(io);

            while (self.generation_queue.pop()) |chunk| {
                g.async(io, Chunk.generateTerrain, .{ chunk });
                try meshes_to_generate.append(allocator, &chunk.mesh);
            }

            try g.await(io);
        } else {
            return;
        }

        var chunks_to_upload: std.ArrayList(*Chunk.Mesh) = .empty;

        var g: std.Io.Group = .init;

        errdefer g.cancel(io);

        while (meshes_to_generate.pop()) |mesh| {
            g.async(io, safeGenerate, .{ mesh, allocator, self });
            try chunks_to_upload.append(allocator, mesh);
        }

        try g.await(io);

        while (chunks_to_upload.pop()) |mesh| {
            mesh.upload();
        }
    }

    pub fn blit(self: *const Level) void {
        var iter = self.chunks.valueIterator();

        while (iter.next()) |chunk| {
            chunk.*.mesh.blit();
        }
    }
};

fn safeGenerate(mesh: *Chunk.Mesh, allocator: std.mem.Allocator, level: *const Level) void {
    mesh.generate(allocator, level) catch |err| {
        std.log.err("{}", .{err});
    };
}