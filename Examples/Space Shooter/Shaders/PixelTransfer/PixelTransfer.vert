#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 vCoord;
out flat ivec2 tSize;

uniform sampler2D tex;

void main(){
    gl_Position = vec4(aPos.x, aPos.y, 0, 1);
    vCoord = aCoord;
    tSize = textureSize(tex,0);
}