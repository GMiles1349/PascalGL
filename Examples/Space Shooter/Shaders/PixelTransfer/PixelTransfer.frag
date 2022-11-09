#version 430 core

out vec4 FragColor;

in vec2 vCoord;
in flat ivec2 tSize;

uniform sampler2D tex;

layout (std430, binding = 2) buffer PixelBuffer
    {
        vec4 Pixel[];
    };

void main(){
    int X;
    int Y;
    int Pos;
    X = int(vCoord.x / tSize.x);
    Y = int(vCoord.y / tSize.y);
    Pos = (Y * tSize.x) + X;
    Pixel[Pos] = texture(tex,vCoord);
    FragColor = Pixel[Pos];
    FragColor.x = FragColor.x * 0.5;
}