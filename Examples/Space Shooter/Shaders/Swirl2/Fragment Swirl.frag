#version 430 core

out vec4 FragColor;

in vec2 vCoord;

uniform sampler2D tex;
uniform vec2 Center;
uniform float planeWidth;
uniform float planeHeight;

void main(){

    float dist;
    float distx;
    float disty;
    float rad;
    float X;
    float Y;

    X = planeWidth * vCoord.x;
    Y = planeHeight * vCoord.y;

    distx = X - Center.x;
    distx = distx * distx;
    disty = Y - Center.y;
    disty = disty * disty;

    dist = sqrt( distx + disty );

    rad = dist * (3.1415 / 180);

    X = Center.x + (dist * cos(rad));
    Y = Center.y + (dist * sin(rad));

    FragColor = texelFetch(tex, ivec2( int(X), int(Y) ), 0);
    FragColor = vec4(0,1,0,1);

}