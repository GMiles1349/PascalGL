#version 430 core

out vec4 FragColor;

in vec2 vCoord;

uniform sampler2D tex;
uniform float planeWidth;
uniform float planeHeight;
uniform vec4 IgnoreColor;

void main(){

    int i;
    int r;
    int z;
    int X;
    int Y;
    int count;
    ivec2 texsize;
    vec4 color[9];
    vec4 testcolor;
    int skip;

    X = int((planeWidth * vCoord.x));
    Y = int((planeHeight * vCoord.y));


    // FragColor = texelFetch(tex,ivec2(X,Y),0);
    FragColor = texture(tex,vec2(vCoord.x, vCoord.y));

    if (FragColor == IgnoreColor || FragColor.w == 0){
        
    }
    else{

        count = 0;

        for ( z = -1 ; z < 1 ; z++ ){
            for ( i = -1 ; i < 1 ; i++ ){

                if (i == X && z == Y){
                    continue;
                }

                // testcolor = texelFetch(tex, ivec2(X + i, Y + z),0);
                testcolor = texture(tex, vec2(vCoord.x + (i/planeWidth), vCoord.y + (z/planeHeight)));
                
                if ( count == 0 ){
                    count++;
                    color[count] = testcolor;
                }
                else{

                    skip = 0;

                    for ( r = 1 ; r < count ; r++ ){
                        if ( testcolor == color[r] ){
                            skip = 1;
                            break;
                        }
                    }

                    if ( skip == 0 ){
                        count++;
                        color[count] = testcolor;
                    }


                }

            }
        }

        if ( count > 0 ){

            for ( i = 1 ; i < count ; i++ ){
                FragColor = mix(FragColor, color[i], 0.5);
            }

        }

    }

}