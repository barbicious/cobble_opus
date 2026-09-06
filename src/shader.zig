const c = @import("c");
const std = @import("std");
const zalgebra = @import("zalgebra");

pub const Shader = struct {
    handle: u32,

    pub fn init(vs_src: []const u8, fs_src: []const u8) !Shader {
        const vs = try createShader(vs_src, c.GL_VERTEX_SHADER);
        const fs = try createShader(fs_src, c.GL_FRAGMENT_SHADER);

        const handle = c.glCreateProgram();
        c.glAttachShader(handle, vs);
        c.glAttachShader(handle, fs);
        c.glLinkProgram(handle);

        var success: i32 = 0;
        c.glGetProgramiv(handle, c.GL_LINK_STATUS, @ptrCast(&success));

        if (success != c.GL_TRUE) {
            var buffer: [1024]u8 = undefined;
            var info_len: u32 = undefined;

            c.glGetProgramiv(handle, c.GL_INFO_LOG_LENGTH, @ptrCast(&info_len));
            c.glGetProgramInfoLog(handle, buffer.len, @ptrCast(&info_len), &buffer);

            std.log.err("Shader linking failed! Error: {s}", .{buffer[0..info_len]});

            return error.ShaderLinkingFailed;
        }

        c.glDeleteShader(vs);
        c.glDeleteShader(fs);

        return .{ .handle = handle };
    }

    pub fn deinit(self: Shader) void {
        c.glDeleteProgram(self.handle);
    }

    pub fn bind(self: Shader) void {
        c.glUseProgram(self.handle);
    }

    pub fn setMat4(self: Shader, name: [*c]const u8, mat4: zalgebra.Mat4) void {
        c.glUniformMatrix4fv(c.glGetUniformLocation(self.handle, name), 1, @intFromBool(false), @ptrCast(&mat4));
    }
};

fn createShader(src: []const u8, @"type": u32) !u32 {
    const shader = c.glCreateShader(@"type");
    c.glShaderSource(shader, 1, @ptrCast(&src), null);
    c.glCompileShader(shader);

    var success: i32 = 0;
    c.glGetShaderiv(shader, c.GL_COMPILE_STATUS, @ptrCast(&success));

    if (success != c.GL_TRUE) {
        var buffer: [1024]u8 = undefined;
        var info_len: u32 = undefined;

        c.glGetShaderiv(shader, c.GL_INFO_LOG_LENGTH, @ptrCast(&info_len));
        c.glGetShaderInfoLog(shader, buffer.len, @ptrCast(&info_len), &buffer);

        std.log.err("Shader compilation failed! Error: {s}", .{buffer[0..info_len]});

        return error.ShaderCompilationFailed;
    }

    return shader;
}
