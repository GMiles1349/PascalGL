#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec4 vFillColor;
in vec4 vBorderColor;
in vec4 vParams; // width (radius), height, borderwidth, shape type (0 = Circle, 1 = Line)
in vec4 vPos;
in vec2 vNormal;

void line();
void findborder();
void circle();
float atan2(in float y, in float x);

float NormalLength;

void main(){

    NormalLength = length(vNormal);

    if (int(floor(vParams.w)) == 0){
        circle();
    }
    else if (vParams.w == 1){
        line();
    }
}


void line(){
    FragColor = vFillColor;
    
    // Draw Borders
    if ( NormalLength >= (vParams.x - vParams.z) / vParams.x ){
        FragColor = vBorderColor;
    }

    // AA edges
    // if (NormalLength >= 0.9 ){
    //     FragColor.w = FragColor.w * (NormalLength);
    // }
}


void circle(){

    float fillend;
    float xdist;
    float ydist;
    float totaldist;
    float Radius;
    int i;

    Radius = vParams.x / 2;

    // get bounds of border and fill
    fillend = Radius - vParams.z;

    totaldist = distance(vec2(vPos), vec2(gl_FragCoord));

    if ((totaldist) <= Radius){

        if (totaldist <= fillend){
            FragColor = vFillColor;
        }
        else {
            FragColor = vBorderColor;

            if (floor(totaldist) == fillend){
                FragColor = mix(vFillColor,vBorderColor,0.5);
            }
        }

        if (floor(totaldist) == Radius){
            FragColor.w = FragColor.w * 0.5;
        }

        // AA edges
        if (NormalLength >= 0.9) {
            FragColor.w = FragColor.w * length(vNormal);
        }

    }
    else{
        discard;
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