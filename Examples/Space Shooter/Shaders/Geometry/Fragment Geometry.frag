#version 430 core

out vec4 FragColor;

in vec4 vColor;
in vec3 vNormal;
in smooth float vNormalLength;
in flat int VertexID;

void main(){
    FragColor = vColor;
}