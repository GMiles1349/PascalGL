#version 430 core

layout (location = 0) in vec2 aPos;
layout (location = 1) in uint aIndex;
layout (location = 3) in vec2 aNormal;

out vec4 vFillColor;
out vec4 vBorderColor;
out vec4 vParams;
out vec4 vPos;
out vec2 vNormal;

struct ShapeStruct{
    vec4 FillColor;
    vec4 BorderColor;
    vec4 Params; // Width (Radius), Height, BorderWidth, Shapetype
    vec4 Pos;
};

layout (std430, binding = 2) buffer ShapeBuffer{
    ShapeStruct shape[];
};

void main(){

    vFillColor = shape[aIndex].FillColor;
    vBorderColor = shape[aIndex].BorderColor;
    vParams = shape[aIndex].Params;
    vPos = shape[aIndex].Pos;
    vNormal = aNormal;

    gl_Position = vec4(aPos.x, aPos.y, 0, 1);

}