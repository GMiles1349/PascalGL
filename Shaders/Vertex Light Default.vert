#version 430 core
layout (location = 0) in vec2 aPos;

out flat int index;
out flat int p;
out vec2 vCoord;
out vec2 vPos;


uniform float planeWidth;
uniform float planeHeight;

void main()
{
    float NewX = (-1 + (aPos.x / planeWidth) * 2);
    float NewY = (1 - (aPos.y / planeHeight) * 2);

    gl_Position =  vec4(NewX,NewY,0,1);

    p = int(floor(gl_VertexID / 4));
    index = int(gl_VertexID / 3);


    vCoord.x = aPos.x / planeWidth;
    vCoord.y = 1 - (aPos.y / planeHeight);

    // vCoord.x = aPos.x;
    // vCoord.y = planeHeight - aPos.y;

};