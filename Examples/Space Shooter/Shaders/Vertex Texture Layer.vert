#version 420 core
layout (location = 0) in vec2 aPos;
layout (location = 1) in vec2 aCoord;

out vec2 vCoord;

uniform mat4 Translation;
uniform mat4 Rotation;
uniform mat4 Scale;


void main()
{

    mat4 Transform;

    Transform = Translation * Scale * Rotation;

    gl_Position = Transform * vec4(aPos.x,aPos.y,0,1);
    vCoord = aCoord;
};