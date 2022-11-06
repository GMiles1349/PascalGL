#version 430 core

layout (location = 0) in vec2 aPos;


struct CircleStruct{
    vec2 Center;
    float Width;
    float BorderWidth;
    vec4 FillColor;
    vec4 BorderColor;
    vec4 Fade;
};

layout (std430, binding = 1) buffer CircleBuffer
{
    CircleStruct Circle[];
};

out flat vec2 fCenter;
out flat float fWidth;
out flat float fBorderWidth;
out flat vec4 fFillColor;
out flat vec4 fBorderColor;
out flat vec4 fFade;

int p;

uniform float planeWidth;
uniform float planeHeight;

void main(){

    gl_Position = vec4(aPos.x, aPos.y, 0, 1);

    p = int(floor(gl_VertexID / 4));

    fCenter = Circle[p].Center;
    fWidth = Circle[p].Width;
    fBorderWidth = Circle[p].BorderWidth;
    fFillColor = Circle[p].FillColor;
    fBorderColor = Circle[p].BorderColor;
    fFade = Circle[p].Fade;

}