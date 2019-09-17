#version 330

precision highp float;
in vec4 exColor;
in vec2 exTexcoord;
out vec4 outColor;

uniform sampler2D ppTexture;
uniform float time;

void main(void) {
	vec2 texC = exTexcoord;
	texC.x += sin((time/200.0)+(texC.y*100.0))/700.0;
	vec4 tex_col = texture2D(ppTexture, texC);
	outColor = exColor * tex_col;
}