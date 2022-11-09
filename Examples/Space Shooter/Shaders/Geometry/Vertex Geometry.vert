#version 430 core

layout (location = 0) in vec3 aPos;
layout (location = 2) in vec3 aNormal;
layout (location = 4) in vec4 bColor;

out vec4 vColor;
out vec3 vNormal;
out smooth float vNormalLength;
out flat int VertexID;

layout (std430, binding = 1) buffer ColorBuffer{
    vec4 aColor[];
};

layout (std430, binding = 3) buffer BorderColorBuffer{
    vec4 aBorderColor[];
};


uniform float planeWidth;
uniform float planeHeight;

void main(){

    float NewX = -1 + ((aPos.x / planeWidth) * 2);
    float NewY = 1 - ((aPos.y / planeHeight) * 2);

    gl_Position = vec4(NewX, NewY, 0, 1);
    vColor = bColor;
    VertexID = int(mod(gl_VertexID,3));
    vNormalLength = 1;
}