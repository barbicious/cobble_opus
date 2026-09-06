const gfx = @import("gfx.zig");

pub const Tile = enum {
    air,
    grass,
    cobblestone,

    pub fn uv(self: Tile) struct { f32, f32 } {
        return switch (self) {
            .air => @panic("Air does not have UV coords!"),
            .grass => .{ 0.0, 0.0 },
            .cobblestone => .{ texture_width, 0.0 },
        };
    }
};

pub const Face = enum {
    front,
    back,
    left,
    right,
    top,
    bottom,
};

pub const max_vertices: usize = 36;

const texture_width: f32 = 8.0 / @as(f32, @floatFromInt(gfx.texture_atlas_width));
const texture_height: f32 = 8.0 / @as(f32, @floatFromInt(gfx.texture_atlas_height));

pub fn vertices(tile: Tile, face: Face, x: f32, y: f32, z: f32) [max_vertices]f32 {
    const u, const v = tile.uv();

    switch (face) {
        .front => {
            return [_]f32{
                1.0 + x, 0.0 + y, 0.0 + z, u + texture_width, v,                  0.7,
                0.0 + x, 0.0 + y, 0.0 + z, u,                 v,                  0.7,
                1.0 + x, 1.0 + y, 0.0 + z, u + texture_width, v + texture_height, 0.7,
                0.0 + x, 0.0 + y, 0.0 + z, u,                 v,                  0.7,
                0.0 + x, 1.0 + y, 0.0 + z, u,                 v + texture_height, 0.7,
                1.0 + x, 1.0 + y, 0.0 + z, u + texture_width, v + texture_height, 0.7,
            };
        },
        .back => {
            return [_]f32{
                0.0 + x, 0.0 + y, 1.0 + z, u,                 v,                  0.5,
                1.0 + x, 0.0 + y, 1.0 + z, u + texture_width, v,                  0.5,
                1.0 + x, 1.0 + y, 1.0 + z, u + texture_width, v + texture_height, 0.5,
                1.0 + x, 1.0 + y, 1.0 + z, u + texture_width, v + texture_height, 0.5,
                0.0 + x, 1.0 + y, 1.0 + z, u,                 v + texture_height, 0.5,
                0.0 + x, 0.0 + y, 1.0 + z, u,                 v,                  0.5,
            };
        },
        .left => {
            return [_]f32{
                0.0 + x, 1.0 + y, 1.0 + z, u + texture_width, v,                  0.8,
                0.0 + x, 1.0 + y, 0.0 + z, u + texture_width, v + texture_height, 0.8,
                0.0 + x, 0.0 + y, 0.0 + z, u,                 v + texture_height, 0.8,
                0.0 + x, 0.0 + y, 0.0 + z, u,                 v + texture_height, 0.8,
                0.0 + x, 0.0 + y, 1.0 + z, u,                 v,                  0.8,
                0.0 + x, 1.0 + y, 1.0 + z, u + texture_width, v,                  0.8,
            };
        },
        .right => {
            return [_]f32{
                1.0 + x, 1.0 + y, 1.0 + z, u + texture_width, v,                  0.6,
                1.0 + x, 0.0 + y, 0.0 + z, u,                 v + texture_height, 0.6,
                1.0 + x, 1.0 + y, 0.0 + z, u + texture_width, v + texture_height, 0.6,
                1.0 + x, 1.0 + y, 1.0 + z, u + texture_width, v,                  0.6,
                1.0 + x, 0.0 + y, 1.0 + z, u,                 v,                  0.6,
                1.0 + x, 0.0 + y, 0.0 + z, u,                 v + texture_height, 0.6,
            };
        },
        .bottom => {
            return [_]f32{
                0.0 + x, 0.0 + y, 0.0 + z, u,                 v + texture_height, 0.4,
                1.0 + x, 0.0 + y, 0.0 + z, u + texture_width, v + texture_height, 0.4,
                1.0 + x, 0.0 + y, 1.0 + z, u + texture_width, v,                  0.4,
                1.0 + x, 0.0 + y, 1.0 + z, u + texture_width, v,                  0.4,
                0.0 + x, 0.0 + y, 1.0 + z, u,                 v,                  0.4,
                0.0 + x, 0.0 + y, 0.0 + z, u,                 v + texture_height, 0.4,
            };
        },
        .top => {
            return [_]f32{
                1.0 + x, 1.0 + y, 1.0 + z, u + texture_width, v,                  0.9,
                1.0 + x, 1.0 + y, 0.0 + z, u + texture_width, v + texture_height, 0.9,
                0.0 + x, 1.0 + y, 0.0 + z, u,                 v + texture_height, 0.9,
                0.0 + x, 1.0 + y, 1.0 + z, u,                 v,                  0.9,
                1.0 + x, 1.0 + y, 1.0 + z, u + texture_width, v,                  0.9,
                0.0 + x, 1.0 + y, 0.0 + z, u,                 v + texture_height, 0.9,
            };
        },
    }
}
