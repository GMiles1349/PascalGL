#version 430 core

out vec4 FragColor;

uniform float Seed;
uniform float planeWidth;
uniform float planeHeight;

float rand3D(in vec3 co);

void main(){
    
    FragColor = vec4(0,0,0, rand3D(vec3(gl_FragCoord.x / planeWidth, gl_FragCoord.y / planeHeight,Seed)));
}


float rand3D(in vec3 co){
    return fract(sin(dot(co.xyz ,vec3(12.9898,78.233,144.7272))) * 43758.5453);
}