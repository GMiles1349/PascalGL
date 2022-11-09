#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 vCoord;
out flat ivec2 texdims;

uniform sampler2D tex;
uniform float planeWidth;
uniform float planeHeight;

void main(){

    float NewX = (-1 + ((aPos.x / planeWidth) * 2));
    float NewY = (1 - ((aPos.y / planeHeight) * 2));

    gl_Position = vec4(NewX, NewY, 0, 1);

    texdims = textureSize(tex,0);
    vCoord = aCoord;


}