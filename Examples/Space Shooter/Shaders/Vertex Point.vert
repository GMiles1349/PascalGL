#version 420 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec4 aColor;
layout (location = 2) in float aSize;

out vec4 vColor;

uniform float planeWidth;
uniform float planeHeight;

void main(){

    float NewX = (-1 + ((aPos.x / planeWidth) * 2));
    float NewY = (1 - ((aPos.y / planeHeight) * 2));

    gl_PointSize = aSize;
    gl_Position = vec4(NewX,NewY,0,1);
    vColor = aColor;
}