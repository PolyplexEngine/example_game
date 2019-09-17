#version 330
in vec2 position;
in vec2 texcoord;
in vec4 color;

uniform mat4 PROJECTION;

out vec4 exColor;
out vec2 exTexcoord;

void main(void) {
	gl_Position = PROJECTION * vec4(position.xy, 0.0, 1.0);
	exTexcoord = texcoord;
	exColor = color;
}