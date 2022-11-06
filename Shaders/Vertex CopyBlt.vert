#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 vCoord;
out flat int sourceWidth;
out flat int sourceHeight;

uniform float planeWidth;
uniform float planeHeight;
uniform sampler2D SourceTex;

void main(){

    float newx = (-1 + (aPos.x / planeWidth) * 2);
    float newy = (1 - (aPos.y / planeHeight) * 2);
    ivec2 texsize;

    gl_Position = vec4(newx,newy,0,1);

    texsize = textureSize(SourceTex,0);
    sourceWidth = texsize.x;
    sourceHeight = texsize.y;
    vCoord.x = aCoord.x / sourceWidth;
    vCoord.y = 1 - (aCoord.y / sourceHeight);

}