#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 texCoord;

uniform float planeWidth;
uniform float planeHeight;

void main() {

    vec2 newPos;

    newPos.x = (-1 + ((aPos.x / planeWidth) * 2) );
    newPos.y = (1 - ((aPos.y / planeHeight) * 2) );

    gl_Position = vec4(newPos.x, newPos.y, 0, 1);

    texCoord = aCoord;

}