#version 430 core
layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;
in flat int p;
in flat int CurVer;

// Buffer SSBOs
layout (std430, binding = 1) buffer CenterBuffer{
    vec2 fCenter[];
};
layout (std430, binding = 2) buffer FillColorBuffer{
    vec4 fFillColor[];
};
layout (std430, binding = 3) buffer BorderColorBuffer{
    vec4 fBorderColor[];
};
layout (std430, binding = 4) buffer DimsBuffer{
    vec2 fDims[];
};
layout (std430, binding = 5) buffer BorderWidthBuffer{
    float fBorderWidth[];
};
layout (std430, binding = 6) buffer CurveBuffer{
    float fCornerCurve[];
};


float Left;
float Top;
float Right;
float Bottom;

// Function Declarations
void main();
void roundcorners();

void main() {

    FragColor = fFillColor[p];

    Left = fCenter[p].x - (fDims[p].x / 2);
    Right = Left + fDims[p].x;

    Top = fCenter[p].y - (fDims[p].y / 2);
    Bottom = Top + fDims[p].y;

    if (gl_FragCoord.x <= Left + fBorderWidth[p] ||
        gl_FragCoord.x >= Right - fBorderWidth[p] ||
        gl_FragCoord.y <= Top + fBorderWidth[p] ||
        gl_FragCoord.y >= Bottom - fBorderWidth[p] ){

            FragColor = fBorderColor[p];

        }
        
    else{
        FragColor = fFillColor[p];
    }


    if (fCornerCurve[p] > 0.5){
        roundcorners();
    }   


}


void roundcorners(){

    vec2 TopLeft;
    vec2 TopRight;
    vec2 BottomLeft;
    vec2 BottomRight;
    float UseAngle;
    float distx;
    float disty;
    float totaldist;
    float maxdist;
    float cWidth;
    float cHeight;

    // Set top Left Center Point
    TopLeft.x = Left + fCornerCurve[p];
    TopLeft.y = Top + fCornerCurve[p];

    if (gl_FragCoord.x <= TopLeft.x && gl_FragCoord.y <= TopLeft.y) {
        
        distx = abs(gl_FragCoord.x - TopLeft.x);
        distx = distx * distx;
        disty = abs(gl_FragCoord.y - TopLeft.y);
        disty = disty * disty;
        totaldist = sqrt(distx + disty);

        FragColor = vec4(0,0,0,0);

        if (totaldist <= fCornerCurve[p]){
            if (totaldist <= fCornerCurve[p] - fBorderWidth[p]){
                FragColor = fFillColor[p];
            }
            else{
                FragColor = fBorderColor[p];
            }
        }

    }

    

    // Set Top Right Cetner Point
    TopRight.x = Right - fCornerCurve[p];
    TopRight.y = Top + fCornerCurve[p];

    if (gl_FragCoord.x >= TopRight.x && gl_FragCoord.y <= TopRight.y) {
        
        distx = abs(gl_FragCoord.x - TopRight.x);
        distx = distx * distx;
        disty = abs(gl_FragCoord.y - TopRight.y);
        disty = disty * disty;
        totaldist = sqrt(distx + disty);

        FragColor = vec4(0,0,0,0);

        if (totaldist <= fCornerCurve[p]){
            if (totaldist <= fCornerCurve[p] - fBorderWidth[p]){
                FragColor = fFillColor[p];
            }
            else{
                FragColor = fBorderColor[p];
            }
        }

    }

    // Set Bottom Left Center POint
    BottomLeft.x = Left + fCornerCurve[p];
    BottomLeft.y = Bottom - fCornerCurve[p];

    if (gl_FragCoord.x <= BottomLeft.x && gl_FragCoord.y >= BottomLeft.y) {
        
        distx = abs(gl_FragCoord.x - BottomLeft.x);
        distx = distx * distx;
        disty = abs(gl_FragCoord.y - BottomLeft.y);
        disty = disty * disty;
        totaldist = sqrt(distx + disty);

        FragColor = vec4(0,0,0,0);

        if (totaldist <= fCornerCurve[p]){
            if (totaldist <= fCornerCurve[p] - fBorderWidth[p]){
                FragColor = fFillColor[p];
            }
            else{
                FragColor = fBorderColor[p];
            }
        }

    }

    // Set Bottom Right Center POint
    BottomRight.x = Right - fCornerCurve[p];
    BottomRight.y = Bottom - fCornerCurve[p];

    if (gl_FragCoord.x >= BottomRight.x && gl_FragCoord.y >= BottomRight.y) {
        
        distx = abs(gl_FragCoord.x - BottomRight.x);
        distx = distx * distx;
        disty = abs(gl_FragCoord.y - BottomRight.y);
        disty = disty * disty;
        totaldist = sqrt(distx + disty);

        FragColor = vec4(0,0,0,0);

        if (totaldist <= fCornerCurve[p]){
            if (totaldist <= fCornerCurve[p] - fBorderWidth[p]){
                FragColor = fFillColor[p];
            }
            else{
                FragColor = fBorderColor[p];
            }
        }

    }

}