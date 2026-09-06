#version 330

layout (location = 0) in vec3 i_pos;
layout (location = 1) in vec2 i_uv;
layout (location = 2) in float i_light;

out vec2 v_uv;
out float v_light;

uniform mat4 u_proj;
uniform mat4 u_view;

void main() {
    gl_Position = u_proj * u_view * vec4(i_pos, 1.0);
    v_uv = i_uv;
    v_light = i_light;
}