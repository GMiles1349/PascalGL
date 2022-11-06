#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 vCoord;
out float texWidth;
out float texHeight;

uniform float planeWidth;
uniform float planeHeight;
uniform sampler2D tex;


void main() {

    vec2 newPos;
    newPos.x = (-1 + (aPos.x / planeWidth) * 2);
    newPos.y = (1 - (aPos.y / planeHeight) * 2);

    gl_Position = vec4(newPos.x, newPos.y, 0, 1);

    ivec2 texsize = textureSize(tex,0);
    texWidth = texsize.x;
    texHeight = texsize.y;
    vCoord.x = aCoord.x / texWidth;
    vCoord.y =  1 - (aCoord.y / texHeight);

}