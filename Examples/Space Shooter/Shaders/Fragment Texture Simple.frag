#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec2 vCoord;
in flat ivec2 texsize;

vec4 TexColor;

uniform sampler2D tex;

void main(){

    TexColor = texture(tex,vCoord);

    if ( TexColor.x > 0.3 ){

        FragColor = vec4(TexColor.x,0,0,TexColor.x);
    }
    else{
        FragColor = vec4(0,0,0,0);
    }
    
}