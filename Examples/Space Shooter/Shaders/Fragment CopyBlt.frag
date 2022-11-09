#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec2 vCoord;
in flat int sourceWidth;
in flat int sourceHeight;

uniform sampler2D SourceTex;
uniform float PixelSize = 0;

vec4 DestColor;
vec4 SourceColor;

void Pixelate();

void main(){

    if (PixelSize <= 1){
        FragColor = texture(SourceTex,vec2(vCoord.x, vCoord.y));

        if (FragColor.w == 0){
            FragColor = vec4(0,0,0,0);
        }
    }
    else{
        Pixelate();
    }
}


void Pixelate(){

    int X;
    int Y;
    vec4 PixelColor;

    X = int(vCoord.x * sourceWidth);
    Y = int(vCoord.y * sourceHeight);
    X = int(X - mod(X,PixelSize));
    Y = int(Y - mod(Y,PixelSize));


    FragColor = texelFetch(SourceTex, ivec2( int(X) , int(Y)),0);

    if (FragColor.w == 0){
        FragColor = vec4(0,0,0,0);
    }
}