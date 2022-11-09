#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 vCoord;

void main(){
    gl_Position = vec4(aPos.x, aPos.y, 0, 1);
    vCoord = aCoord;
}