#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec2 vCoord;
in flat ivec2 texsize;

uniform sampler2D Texture0;
uniform vec4 TextColor;
uniform vec4 BorderColor;
uniform int BorderSize;
uniform float planeWidth;
uniform float planeHeight;

layout(std430, binding = 3) buffer Colors
{
    vec4 fColor[][];
};

void main() {

    vec4 nColor;
    int breakloop = 0;
    int doblend = 0;
    int foundtcolor = 0;
    int i;
    int z;
    int X;
    int Y;

    X = int(gl_FragCoord.x);
    Y = int(texsize.y - gl_FragCoord.y);

    FragColor = texelFetch( Texture0, ivec2(X,Y), 0 );

    if (FragColor.w == 0){

            for (int i = -(BorderSize) ; i <= (BorderSize) ; i++ ){
                for (int z = -(BorderSize) ; z <= (BorderSize) ; z++ ){

                    if ( abs(i + z) <= (BorderSize * 1.4) ){

                        nColor = texelFetch( Texture0, ivec2( X + i , Y - z), 0 );

                        if (nColor.w != 0){
                            foundtcolor = 1;
                            breakloop = 1;
                            break;
                        }
                    }

                }

                if (breakloop == 1){
                    break;
                }

            }


            if (foundtcolor == 1){
                FragColor = BorderColor;
            }

    }


}