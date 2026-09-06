const tile = @import("tile.zig");
const c = @import("c");

pub const Chunk = struct {
    pub const Mesh = struct {
        chunk: *const Chunk,
        vertices: [(width * height * depth) * tile.max_vertices]f32,
        vao: u32,
        vbo: u32,

        pub fn init(chunk: *const Chunk) Mesh {
            var tiles: usize = 0;

            var vertices: [(width * height * depth) * 216]f32 = undefined;

            for (0..chunk.tiles.len) |tile_idx| {
                const x = tile_idx % width;
                const z = (tile_idx / width) % height;
                const y = tile_idx / (width * height);

                const tile_type = chunk.tiles[tile_idx];

                const tile_vertices = tile.vertices(tile_type, .back, @floatFromInt(x), @floatFromInt(y), @floatFromInt(z))
                    ++ tile.vertices(tile_type, .front, @floatFromInt(x), @floatFromInt(y), @floatFromInt(z))
                    ++ tile.vertices(tile_type, .left, @floatFromInt(x), @floatFromInt(y), @floatFromInt(z))
                    ++ tile.vertices(tile_type, .right, @floatFromInt(x), @floatFromInt(y), @floatFromInt(z))
                    ++ tile.vertices(tile_type, .bottom, @floatFromInt(x), @floatFromInt(y), @floatFromInt(z))
                    ++ tile.vertices(tile_type, .top, @floatFromInt(x), @floatFromInt(y), @floatFromInt(z));

                @memcpy(vertices[(tiles * 216)..(tiles * 216 + 216)], tile_vertices[0..]);

                tiles += 1;
            }

            var vao: u32 = 0;
            c.glGenVertexArrays(1, &vao);
            c.glBindVertexArray(vao);

            var vbo: u32 = 0;
            c.glGenBuffers(1, &vbo);
            c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);

            c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(f32) * (width * height * depth) * 216, &vertices, c.GL_STREAM_DRAW);

            c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(0));
            c.glEnableVertexAttribArray(0);
            c.glVertexAttribPointer(1, 2, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(3 * @sizeOf(f32)));
            c.glEnableVertexAttribArray(1);
            c.glVertexAttribPointer(2, 1, c.GL_FLOAT, c.GL_FALSE, 6 * @sizeOf(f32), @ptrFromInt(5 * @sizeOf(f32)));
            c.glEnableVertexAttribArray(2);

            return .{
                .chunk = chunk,
                .vertices = undefined,
                .vao = vao,
                .vbo = vbo,
            };
        }

        pub fn deinit(self: Mesh) void {
            c.glDeleteBuffers(1, &self.vbo);
            c.glDeleteVertexArrays(1, &self.vao);
        }

        pub fn blit(self: Mesh) void {
            _ = self;
            c.glDrawArrays(c.GL_TRIANGLES, 0, (width * height * depth) * 216);
        }
    };

    const width: u32 = 16;
    const height: u32 = 16;
    const depth: u32 = 16;

    tiles: [width * height * depth]tile.Tile,
    mesh: Mesh,

    pub fn init(chunk: *Chunk) void {
        var tiles: [width * height * depth]tile.Tile = [_]tile.Tile{ .cobblestone } ** (width * height * depth);

        @memcpy(tiles[(width * depth * 15)..(width * depth * 16)], &[_]tile.Tile{ .grass } ** (width * depth));

        chunk.tiles = tiles;
        chunk.mesh = .init(chunk);
    }

    pub inline fn tileAt(self: Chunk, x: usize, y: usize, z: usize) tile.Tile {
        return self.tiles[x + width * (y + height * z)];
    }

    pub inline fn setTile(self: Chunk, x: usize, y: usize, z: usize, placed_tile: tile.Tile) void {
        self.tiles[x + width * (y + height * z)] = placed_tile;
    }
};