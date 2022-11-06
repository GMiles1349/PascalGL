#version 430 core

layout (location = 0) in vec2 aPos;

out flat int p;
out flat int CurVer;

uniform float planeWidth;
uniform float planeHeight;

void main(){

    float NewX = (-1 + ((aPos.x / planeWidth) * 2));
    float NewY = (1 - ((aPos.y / planeHeight) * 2));
    
    gl_Position = vec4(NewX, NewY, 0, 1);

    // send what is essentially the index ID of the circle being drawn to the frag shader
    p = int(floor(gl_VertexID / 4));
    CurVer = int(floor(mod(gl_VertexID,4)));
}