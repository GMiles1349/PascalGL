#version 430 core

out vec4 FragColor;

in vec2 vCoord;

uniform float PixelSize;
uniform sampler2D tex;
uniform float planeWidth;
uniform float planeHeight;

void main(){

    int X;
    int Y;
    vec4 PixelColor;

    X = int(gl_FragCoord.x);
    Y = int(gl_FragCoord.y);
    X = int(X - mod(X,PixelSize));
    Y = int(Y - mod(Y,PixelSize));


    FragColor = texelFetch(tex, ivec2( X - mod(X,PixelSize), Y - mod(Y,PixelSize)),0);
}