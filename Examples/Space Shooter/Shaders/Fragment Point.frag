#version 420 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec4 vColor;

void main(){
    FragColor = vColor;
}