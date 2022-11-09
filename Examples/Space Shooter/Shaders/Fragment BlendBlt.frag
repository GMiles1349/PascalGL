#version 430 core

out vec4 FragColor;

in vec2 vCoord;
in vec2 sCoord;

uniform sampler2D SourceTex;
uniform sampler2D DestTex;

vec4 DestColor;
vec4 SourceColor;

void main(){

    DestColor = texture(DestTex,vec2(vCoord.x, 1- vCoord.y));
    SourceColor = texture(SourceTex,vec2(sCoord.x, 1 - sCoord.y));
    FragColor = DestColor * SourceColor;
    FragColor.w = SourceColor.w;
}