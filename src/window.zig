const c = @import("c");
const std = @import("std");

var window: Window = undefined;

fn handleGlfwError() noreturn {
    var buffer: []const u8 = undefined;

    // Getting an error message, can return an error,
    // who designed this api? Is there a "glfwGetErrorGetError()"?
    _ = c.glfwGetError(@ptrCast(&buffer));

    @panic(buffer);
}

fn framebufferSizeCallback(handle: ?*c.GLFWwindow, width: i32, height: i32) callconv(.c) void {
    _ = handle;

    window.width = width;
    window.height = height;

    c.glViewport(0, 0, window.width, window.height);
}

fn cursorPosCallback(handle: ?*c.GLFWwindow, x: f64, y: f64) callconv(.c) void {
    _ = handle;

    if (window.mouse.first) {
        window.mouse.x = @floatCast(x);
        window.mouse.y = @floatCast(y);

        window.mouse.first = false;
    }

    window.mouse.delta_x = @as(f32, @floatCast(x)) - window.mouse.x;
    window.mouse.delta_y = window.mouse.y - @as(f32, @floatCast(y));

    window.mouse.x = @floatCast(x);
    window.mouse.y = @floatCast(y);
}

pub const Window = struct {
    handle: *c.GLFWwindow,
    width: i32,
    height: i32,
    mouse: struct {
        first: bool = true, // first handle in the callback, the delta is cooked without this flag

        // x/y position this frame
        x: f32 = 0.0,
        y: f32 = 0.0,

        // x/y change between frames
        delta_x: f32 = 0.0,
        delta_y: f32 = 0.0,
    },
    keyboard: struct {
        const Keyboard = @This();

        previous_keys: [c.GLFW_KEY_LAST]bool = [_]bool{ false } ** c.GLFW_KEY_LAST,
        current_keys: [c.GLFW_KEY_LAST]bool = [_]bool{ false } ** c.GLFW_KEY_LAST,

        fn tick(self: *Keyboard) void {
            @memcpy(&self.previous_keys, &self.current_keys);

            for (0..c.GLFW_KEY_LAST) |key_idx| {
                self.current_keys[key_idx] = c.glfwGetKey(window.handle, @intCast(key_idx)) == c.GLFW_PRESS;
            }
        }
    },

    pub fn init(title: [:0]const u8, width: i32, height: i32) !void {
        if (c.glfwInit() != c.GLFW_TRUE) {
            handleGlfwError();
        }

        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 3);
        c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 3);

        const handle = c.glfwCreateWindow(width, height, title, null, null) orelse {
            handleGlfwError();
        };

        c.glfwMakeContextCurrent(handle);

        if (c.gladLoadGLLoader(@ptrCast(&c.glfwGetProcAddress)) != c.GL_TRUE) {
            return error.OpenGLError;
        }

        c.glfwSetInputMode(handle, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);

        _ = c.glfwSetFramebufferSizeCallback(handle, &framebufferSizeCallback);
        _ = c.glfwSetCursorPosCallback(handle, &cursorPosCallback);

        window = .{
            .width = width,
            .height = height,
            .handle = handle,
            .mouse = .{},
            .keyboard = .{},
        };
    }

    pub fn deinit() void {
        c.glfwDestroyWindow(window.handle);
        c.glfwTerminate();
    }

    pub fn isKeyDown(key: i32) bool {
        const key_idx: usize = @intCast(key);

        return window.keyboard.previous_keys[key_idx] and window.keyboard.current_keys[key_idx];
    }

    pub fn isGood() bool {
        window.mouse.delta_x = 0.0;
        window.mouse.delta_y = 0.0;

        c.glfwPollEvents();

        window.keyboard.tick();

        return c.glfwWindowShouldClose(window.handle) == c.GLFW_FALSE;
    }

    pub fn isMouseDown(button: i32) bool {
        return c.glfwGetMouseButton(window.handle, button) == c.GLFW_PRESS;
    }

    pub fn swapBuffers() void {
        c.glfwSwapBuffers(window.handle);
    }

    pub fn deltaTime() f32 {
        const state = struct {
            var last_time: f32 = 0.0;
        };

        const now_time: f32 = @floatCast(c.glfwGetTime());
        const delta_time: f32 = now_time - state.last_time;
        state.last_time = now_time;

        return delta_time;
    }

    pub fn mouseDelta(sensitivity: f32) struct { f32, f32 } {
        return .{
            window.mouse.delta_x * sensitivity,
            window.mouse.delta_y * sensitivity,
        };
    }
};
