#version 430 core
layout(origin_upper_left) in vec4 gl_FragCoord;


out vec4 FragColor;

in vec2 vCoord;
in flat int index;

layout (std430, binding = 2) buffer bLightCenter{
    vec2 Center[];
};

layout (std430, binding = 3) buffer bLightColor{
    vec4 LightColor[];
};

layout (std430, binding = 4) buffer bLightRadius{
    float Radius[];
};

layout (std430, binding = 5) buffer bLightRadiance{
    float Radiance[];
};

uniform float GlobalLight;
uniform sampler2D undermap;
uniform sampler2D lightmap;
uniform float planeWidth;
uniform float planeHeight;


float DistX;
float DistY;
float TotalDist;
float Ratio;
vec4 undercolor;
vec4 lightmapcolor;
float anglediff;
float angle;
float correctangle;
float halfpi = float(3.1415 / 2);

void traceback();
float atan2(in float y, in float x);

void main(){

    lightmapcolor = texelFetch(lightmap, ivec2(gl_FragCoord.x, planeHeight - gl_FragCoord.y),0);

    angle = atan2(gl_FragCoord.y - Center[index].y, gl_FragCoord.x - Center[index].x);

    DistX = (gl_FragCoord.x - Center[index].x);
    DistX = DistX * DistX;
    DistY = (gl_FragCoord.y - Center[index].y);
    DistY = DistY * DistY;
    TotalDist = sqrt(DistX + DistY);

    if (TotalDist <= Radius[index]){
        
        Ratio = 1 - (TotalDist / Radius[index]);
        Ratio = Ratio * (Radiance[index]);
        FragColor = LightColor[index];
        FragColor.w = (Ratio);

        if (TotalDist > 20){
            traceback();
        }


    }
    else{
        discard;    
    }

}


void traceback(){

    int hitcount;
    float walkdist;
    vec2 curpos;
    vec2 moveval;
    
    moveval.x = 1.5 * cos(angle - 3.1415);
    moveval.y = 1.5 * sin(angle - 3.1415);

    curpos = vec2(gl_FragCoord.x, gl_FragCoord.y);
    // curpos = Center;

    while (walkdist < (TotalDist-20)){

        lightmapcolor = texelFetch(lightmap, ivec2( int(curpos.x), int(planeHeight - curpos.y) ) , 0); 

        if (lightmapcolor.x != 0){
            if (lightmapcolor.x < 1){
                FragColor.w = FragColor.w * 0.75;
            }
            else{
                FragColor = vec4(0,0,0,0);
            }

        }
        

            curpos.x = curpos.x + moveval.x;
            curpos.y = curpos.y + moveval.y;
            walkdist = walkdist + abs(moveval.x) + abs(moveval.y);
    }


}

float atan2(in float y, in float x) {

    float pi = float(3.14159265358979);

    if (x > 0){
        return(atan(y / x));
    }
    else if ( x < 0 && y > 0){
        return(atan(y / x) + pi);
    }
    else if (x < 0 && y < 0 ){
        return (atan(y / x) - pi); 
    }   
    else if (x == 0 && y > 0){
        return(pi / 2);
    } 
    else if (x == 0 && y < 0){
        return(-pi / 2);
    } 
}
