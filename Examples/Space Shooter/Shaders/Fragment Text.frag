#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec2 vCoord;

uniform sampler2D tex;
uniform vec4 TextColor;
uniform int HasGradient;
uniform vec4 GradientLeft;
uniform vec4 GradientRight;
uniform float GradientOffset;
uniform float planeWidth;
uniform float planeHeight;
uniform float TextWidth;
uniform int BorderSize;
uniform vec4 BorderColor;

float rollover(in float value);

void main(){

    vec4 tcol;
    vec4 UseColor;
    ivec2 tSize = textureSize(tex,0);
    float percent;

    // use text color or gradient colors

    if (HasGradient == 0){
        UseColor = TextColor;
    }
    else{
        percent = (gl_FragCoord.x  / TextWidth);
        // percent = rollover(percent);

        UseColor.x = (GradientLeft.x * (1-percent)) + (GradientRight.x * (1 - (1-percent)));
        UseColor.y = (GradientLeft.y * (1-percent)) + (GradientRight.y * (1 - (1-percent)));
        UseColor.z = (GradientLeft.z * (1-percent)) + (GradientRight.z * (1 - (1-percent)));
        UseColor.w = (GradientLeft.w * (1-percent)) + (GradientRight.w * (1 - (1-percent)));
    }

    FragColor = vec4(0,0,0,0);
    tcol = texture(tex,vec2( vCoord.x / tSize.x, vCoord.y / tSize.y));

    if (tcol.x != 0 && tcol.y == 0 ){
        if (BorderSize > 0){
            FragColor = UseColor;
        }
        else{
            FragColor = UseColor;
        }
    }
    else if ( tcol.x == 0 && tcol.y > 0 ) {
        if ( (BorderSize) < tcol.y * 10 ) {
            discard;      
        }
        else{
            FragColor = BorderColor;
        }
        
    }
    else{
        discard;
    }

}


float rollover(in float value){

    if (value >= 1 && value < 2){
        value = 1 - (value - 1);
    }
    else if (value >= 2){
        value = value - 2;
    }

    return value;
}

