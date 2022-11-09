#version 430 core

out vec4 FragColor;

in vec2 vCoord;

uniform sampler2D tex;

void main(){
    FragColor = texture(tex,vCoord);
}