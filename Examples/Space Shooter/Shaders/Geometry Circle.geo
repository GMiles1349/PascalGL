#version 430 core
layout (points) in;
layout(triangle_strip, max_vertices = 4) out;

in VS_OUT{
    vec2 gCenter;
    float gWidth;
    float gBorderWidth;
    vec4 gFillColor;
    vec4 gBorderColor;
    vec4 gFade;
    float dWidth;
    float dHeight;
} vsOut[];

out vec2 fCenter;
out float fWidth;
out float fBorderWidth;
out vec4 fFillColor;
out vec4 fBorderColor;
out vec4 fFade;

uniform float planeWidth;
uniform float planeHeight;

void main(){

    fCenter = vsOut[0].gCenter;
    fWidth = vsOut[0].gWidth;
    fBorderWidth = vsOut[0].gBorderWidth;
    fFillColor = vsOut[0].gFillColor;
    fBorderColor = vsOut[0].gBorderColor;
    fFade = vsOut[0].gFade;

    vec2 gPos;
    

    // Top Left
    gPos.x = gl_in[0].gl_Position.x - vsOut[0].dWidth;
    gPos.y = gl_in[0].gl_Position.y - vsOut[0].dHeight;
    gl_Position = vec4(gPos,0,1);
    EmitVertex();

    // Bottom Left
    gPos.x = gl_in[0].gl_Position.x - vsOut[0].dWidth;
    gPos.y = gl_in[0].gl_Position.y + vsOut[0].dHeight;
    gl_Position = vec4(gPos,0,1);
    EmitVertex();

    // Top Right
    gPos.x = gl_in[0].gl_Position.x + vsOut[0].dWidth;
    gPos.y = gl_in[0].gl_Position.y - vsOut[0].dHeight;
    gl_Position = vec4(gPos,0,1);
    EmitVertex();

    // Bottom Right
    gPos.x = gl_in[0].gl_Position.x + vsOut[0].dWidth;
    gPos.y = gl_in[0].gl_Position.y + vsOut[0].dHeight;
    gl_Position = vec4(gPos,0,1);
    EmitVertex();

    

    EndPrimitive();
}