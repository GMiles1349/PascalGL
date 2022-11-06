#version 430 core

out vec4 FragColor;

in vec2 texCoord;

uniform sampler2D tex;
uniform sampler2D lighttex;
uniform float planeWidth;
uniform float planeHeight;
uniform float GlobalLight;

vec4 undercolor;
vec4 lightcolor;
vec4 lightsample[9];


void main(){

    int i;
    vec2 curpos;
    curpos.x = texCoord.x * planeWidth;
    curpos.y = texCoord.y * planeHeight;

    lightsample[0] = texelFetch(lighttex,ivec2(curpos.x, curpos.y),0);
    lightsample[1] = texelFetch(lighttex,ivec2(curpos.x, curpos.y - 1),0);
    lightsample[2] = texelFetch(lighttex,ivec2(curpos.x, curpos.y + 1),0);
    lightsample[3] = texelFetch(lighttex,ivec2(curpos.x - 1, curpos.y),0);
    lightsample[4] = texelFetch(lighttex,ivec2(curpos.x + 1, curpos.y),0);
    lightsample[5] = texelFetch(lighttex,ivec2(curpos.x - 1, curpos.y - 1),0);
    lightsample[6] = texelFetch(lighttex,ivec2(curpos.x - 1, curpos.y + 1),0);
    lightsample[7] = texelFetch(lighttex,ivec2(curpos.x + 1, curpos.y - 1),0);
    lightsample[8] = texelFetch(lighttex,ivec2(curpos.x + 1, curpos.y + 1),0);

    for ( i = 0 ; i < 9 ; i++ ) {
        lightcolor = lightcolor + lightsample[i];
    }

    lightcolor = lightcolor / 9;

    undercolor = texture(tex,texCoord);
    // lightcolor = texture(lighttex,texCoord);
    FragColor = undercolor * lightcolor;
    FragColor.w = lightcolor.w;

}