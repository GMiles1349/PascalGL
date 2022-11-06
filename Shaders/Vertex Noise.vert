#version 420 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec4 inColor;

out vec4 vColor;

uniform mat4 Scale;

void main(){


    gl_Position = Scale * vec4(aPos.x, aPos.y,0,1);
    gl_PointSize = 2;
    vColor = inColor;

}