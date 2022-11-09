#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec2 vCoord;

vec4 TexColor;
vec4 CheckColor;
ivec2 Size;
int CheckX;
int CheckY;
int TexX;
int TexY;
int I;
int Z;
float Dist;
float CheckDist;
float Per;
bool dobreak;

uniform sampler2D tex;
uniform float planeHeight;

void FindSDF();

void main(){

    Size = textureSize(tex,0);
    CheckX = int(gl_FragCoord.x);
    CheckY = int(gl_FragCoord.y);
    TexX = CheckX;
    TexY =  Size.y - CheckY;
    FragColor = vec4(0,0,0,1);

    // check if current fragment is within bounds of destination texture + 5
    if ( TexX >= 0 && TexX < Size.x && TexY >= 0 && TexY < Size.y) {

            TexColor = texelFetch(tex,ivec2(TexX, TexY),0);
            if (TexColor.x != 0) {
                FragColor = vec4(TexColor.x,0,0,TexColor.x);
            }
            else {
                FindSDF();
            }
    }
    else{
        FindSDF();
    }
     
}

void FindSDF(){

    CheckDist = 0;
    Dist = 0;

    for ( I = int(CheckX) - 5 ; I <= int(CheckX) + 5 ; I++ ){
        for ( Z = int(CheckY) - 5 ; Z <= int(CheckY) + 5 ; Z++ ){

            TexX = I;
            TexY = Size.y - Z;

            if ( TexX >= 0 && TexX < Size.x) {
                if (TexY >= 0 && TexY < Size.y) {

            
                    CheckColor = texelFetch(tex,ivec2(TexX, TexY),0);

                    if (CheckColor.x != 0){
                        CheckDist = abs( distance (vec2(CheckX, CheckY), vec2(I,Z) ) );

                        if (CheckDist < Dist || Dist == 0) {
                            if ( CheckDist <= 5 ){
                                Dist = CheckDist;
                            }
                        }

                    }
            
                }
            }


        }

    }

    // if Smallest distance != 0, 
    if (Dist != 0) {
        
        if (Dist > 4){
        Per = 0.5;
        }
        else if (Dist > 3){
            Per = 0.4;
        }
        else if (Dist > 2){
            Per = 0.3;
        }
        else if (Dist > 1){
            Per = 0.2;
        }
        else{
            Per = 0.1;
        }

        FragColor = vec4(0,Per,0,1); 
    }

}