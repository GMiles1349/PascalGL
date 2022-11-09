#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 vCoord;

uniform float planeWidth;
uniform float planeHeight;

void main(){

    float newx = (-1 + (aPos.x / planeWidth) * 2);
    float newy = (1 - (aPos.y / planeHeight) * 2);

    gl_Position = vec4(newx,newy,0,1);
    vCoord = aCoord;
}