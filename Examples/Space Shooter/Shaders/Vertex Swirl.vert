#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 sCoord;
out vec2 Center;

uniform float planeWidth;
uniform float planeHeight;
uniform vec2 inCenter;
uniform sampler2D tex;

void main(){

    float angle = distance(vec2(aPos.x, aPos.y), inCenter);

    vec2 newPos;
    newPos.x = (-1 + ((aPos.x / planeWidth) * 2) );
    newPos.y = (1 - ((aPos.y / planeHeight) * 2) );

    mat2 rotmat = mat2(cos(angle), -sin(angle), 
                   sin(angle), cos(angle));

    newPos = newPos * rotmat;
    
    ivec2 texsize = textureSize(tex,0);

    gl_Position = vec4(newPos.x, newPos.y, 0, 1);

    sCoord.x = aCoord.x / texsize.x;
    sCoord.y = 1 - (aCoord.y / texsize.y);

    Center.x = 0.5;
    Center.y = 0.5;
}