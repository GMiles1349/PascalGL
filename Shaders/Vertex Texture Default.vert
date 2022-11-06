#version 430 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 vCoord;
out vec2 sCoord;

uniform float planeWidth;
uniform float planeHeight;

void main()
{    
    float NewX;
    float NewY;

    NewX = -1 + ((aPos.x / planeWidth) * 2);
    NewY = 1 - ((aPos.y / planeHeight) * 2);
    
    gl_Position = vec4(NewX, NewY, 0, 1);
    vCoord = aCoord;
};