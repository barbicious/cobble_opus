#version 330

in vec2 v_uv;
in float v_light;

out vec4 o_color;

uniform sampler2D texture_sampler;

void main() {
    o_color = texture(texture_sampler, v_uv) * v_light;
}