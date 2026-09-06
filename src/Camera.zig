const zalgebra = @import("zalgebra");
const Window = @import("window.zig").Window;
const c = @import("c");
const std = @import("std");

const Camera = @This();

const up = zalgebra.Vec3.fromSlice(&[_]f32{ 0.0, 1.0, 0.0 });
const speed: f32 = 2.5;
const sensitivity: f32 = 0.1;

position: zalgebra.Vec3,
front: zalgebra.Vec3,
direction: zalgebra.Vec3,
yaw: f32,
pitch: f32,

pub fn init(x: f32, y: f32, z: f32) Camera {
    const front: zalgebra.Vec3 = .fromSlice(&[_]f32{ 0.0, 0.0, -1.0 });

    return .{
        .position = .fromSlice(&[_]f32{ x, y, z }),
        .front = front,
        .direction = front,
        .yaw = -90.0,
        .pitch = 0.0,
    };
}

pub fn viewMatrix(self: Camera) zalgebra.Mat4x4(f32) {
    return .lookAt(self.position, self.position.add(self.front), up);
}

pub fn tick(self: *Camera, dt: f32) void {
    const right = self.front.cross(up).norm();

    if (Window.isKeyDown(c.GLFW_KEY_A)) {
        self.position = self.position.sub(right.scale(speed * dt));
    }

    if (Window.isKeyDown(c.GLFW_KEY_D)) {
        self.position = self.position.add(right.scale(speed * dt));
    }

    if (Window.isKeyDown(c.GLFW_KEY_W)) {
        self.position = self.position.add(self.front.scale(speed * dt));
    }

    if (Window.isKeyDown(c.GLFW_KEY_S)) {
        self.position = self.position.sub(self.front.scale(speed * dt));
    }

    const mouse_delta_x, const mouse_delta_y = Window.mouseDelta(sensitivity);

    if (mouse_delta_x != 0 or mouse_delta_y != 0) {
        self.yaw += mouse_delta_x;
        self.pitch = std.math.clamp(self.pitch + mouse_delta_y, -89.0, 89.0);

        self.front = zalgebra.Vec3.fromSlice(&[_]f32{ @cos(zalgebra.toRadians(self.yaw)) * @cos(zalgebra.toRadians(self.pitch)), @sin(zalgebra.toRadians(self.pitch)), @sin(zalgebra.toRadians(self.yaw)) * @cos(zalgebra.toRadians(self.pitch)) });
    }
}