#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;
layout (location = 2) in vec2 bCoord;

out vec2 vCoord;
out vec2 sCoord;
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

    vCoord = aCoord;
    sCoord = bCoord;
    texsize = textureSize(SourceTex,0);
    sourceWidth = texsize.x;
    sourceHeight = texsize.y;

}