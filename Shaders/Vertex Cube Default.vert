#version 430 core
layout (location = 0) in vec3 aPos;

out vec4 color;

uniform float planeWidth;
uniform float planeHeight;

void main()
{    

    float NewX;
    float NewY;
    int curface;

    NewX = -1 + ((aPos.x / planeWidth) * 2);
    NewY = 1 - ((aPos.y / planeHeight) * 2);
    
    gl_Position = vec4(NewX, NewY, 0, 1);

    curface = int(gl_VertexID / 6);

    if (curface == 0){
        color = vec4(1,0,0,0.5);
    }
    else if (curface == 1){
        color = vec4(0,1,0,0.5);
    }
    
};