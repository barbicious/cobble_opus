const std = @import("std");
const zstbi = @import("zstbi");
const c = @import("c");

pub const texture_atlas_width: i16 = 256;
pub const texture_atlas_height: i16 = 256;

pub fn initTextureAtlas(allocator: std.mem.Allocator, io: std.Io) !void {
    zstbi.init(io, allocator);
    zstbi.setFlipVerticallyOnLoad(true);

    var image: zstbi.Image = try .loadFromFile("res/texture/textureatlas.png", 4);
    defer image.deinit();

    var handle: u32 = 0;
    c.glGenTextures(1, &handle);
    c.glBindTexture(c.GL_TEXTURE_2D, handle);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_S, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_WRAP_T, c.GL_REPEAT);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MIN_FILTER, c.GL_NEAREST);
    c.glTexParameteri(c.GL_TEXTURE_2D, c.GL_TEXTURE_MAG_FILTER, c.GL_NEAREST);
    c.glTexImage2D(c.GL_TEXTURE_2D, 0, c.GL_RGBA, texture_atlas_width, texture_atlas_height, 0, c.GL_RGBA, c.GL_UNSIGNED_BYTE, @ptrCast(image.data));
    c.glGenerateMipmap(c.GL_TEXTURE_2D);
}
