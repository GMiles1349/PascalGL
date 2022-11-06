#version 430 core
layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec2 vCoord;
in flat ivec2 texdims;

uniform sampler2D tex;
uniform float planeWidth;
uniform float planeHeight;
uniform vec2 Center;

vec4 TestColor;
vec4 ReplaceColor;

float atan2(in float y, in float x);

void main(){

    float CurX = vCoord.x;
    float CurY = 1 - vCoord.y;
    float Angle = atan2((CurY - Center.y), (CurX - Center.x));
    float MoveX = (1 * cos(Angle)) / planeWidth;
    float MoveY = (1 * sin(Angle)) / planeHeight;
    bool Hit = false;
    float Dist;
    float DistX = (CurX - Center.x);
    float DistY = (CurY - Center.y);
    float TravelDist = 0;

    Dist = sqrt( (DistX * DistX) + (DistY * DistY) );

    ReplaceColor = texture(tex,Center);

    while (Hit == false){

        CurX = CurX + MoveX;
        CurY = CurY + MoveX;

        TestColor = texture(tex,vec2(CurX, CurY));
        if ( TestColor != ReplaceColor) {
            Hit = true;
            break;
        }

        TravelDist = TravelDist + abs(MoveX);
        TravelDist = TravelDist + abs(MoveY);

        if ( TravelDist >= Dist){
            break;
        }
    } // end while

    FragColor = vec4(1,0,1,0.5);

    if (Hit == false){
        FragColor = ReplaceColor;
    }
    else {
        
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