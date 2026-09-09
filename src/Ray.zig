const zalgebra = @import("zalgebra");

const Ray = @This();

start: zalgebra.Vec3,
end: zalgebra.Vec3,
direction: zalgebra.Vec3,

pub fn init(position: zalgebra.Vec3, direction: zalgebra.Vec3) Ray {
    return .{
        .start = position,
        .end = position,
        .direction = direction
    };
}

pub fn step(self: *Ray, scale: f32) void {
    const yaw = zalgebra.toRadians(self.direction.x() + 90.0);
    const pitch = zalgebra.toRadians(-self.direction.y());

    self.end.xMut().* -= @cos(yaw) * scale;
    self.end.yMut().* -= @tan(pitch) * scale;
    self.end.zMut().* -= @sin(yaw) * scale;
}

pub fn distance(self: *const Ray) f32 {
    return self.start.distance(self.end);
}