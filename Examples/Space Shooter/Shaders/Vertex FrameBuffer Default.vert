#version 330 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 vCoord;

uniform mat4 Translation;
uniform mat4 Scale;
uniform mat4 Rotation;

uniform float planeWidth;
uniform float planeHeight;

mat4 Transform;

void main()
{

    float NewX = -1 + ((aPos.x / planeWidth) * 2);
    float NewY = 1 - ((aPos.y / planeHeight) * 2);

    Transform = Translation * Scale * Rotation;

    gl_Position = Transform * vec4(aPos.x, aPos.y, 0, 1);
    vCoord = aCoord;
};