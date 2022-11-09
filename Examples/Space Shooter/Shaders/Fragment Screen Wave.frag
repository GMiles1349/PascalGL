#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec2 vCoord;

uniform sampler2D UseTexture;
uniform int WaveY;
uniform float xRatio;

void main(){

    float YOffset;
    float NewX;

    YOffset = mod(gl_FragCoord.x, WaveY) * vCoord.y;

    NewX = gl_FragCoord.y + YOffset;
    NewX = NewX * xRatio;


    FragColor = texture(UseTexture,vec2(NewX,vCoord.y));
}