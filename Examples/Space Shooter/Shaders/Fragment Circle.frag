#version 430 core
layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in flat vec2 fCenter;
in flat float fWidth;
in flat float fBorderWidth;
in flat vec4 fFillColor;
in flat vec4 fBorderColor;
in flat vec4 fFade;


void main() {

    float fillend;
    float borderstart;
    float borderend;
    float xdist;
    float ydist;
    float totaldist;
    float Radius;
    float FadeFactor;
    float FadeDiff;

    Radius = fWidth / 2;

    // get bounds of border and fill
    fillend = Radius - fBorderWidth;
    borderstart = fillend;
    borderend = Radius;

    // calc distance from center
    xdist = (fCenter.x - gl_FragCoord.x);
    xdist = xdist * xdist;
    ydist = (fCenter.y - gl_FragCoord.y);
    ydist = ydist * ydist;
    totaldist = (sqrt(xdist + ydist));

    if ((totaldist) <= Radius){

        if (totaldist <= fillend){
            FragColor = fFillColor;
        }
        else {
            FragColor = fBorderColor;

            if (floor(totaldist) == fillend){
                FragColor = mix(fFillColor,fBorderColor,0.5);
            }
        }

        if (fFade.x == 1){
            FadeDiff = abs(fFillColor.w - fFade.y);
            FadeFactor = 1 - fFade.y;
            FragColor.w = fFillColor.w - (FadeDiff * (totaldist / Radius));
        }

        // if (floor(totaldist) == Radius){
        //     FragColor.w = FragColor.w * 0.5;
        // }

    }
    else{
        discard;
    }


}