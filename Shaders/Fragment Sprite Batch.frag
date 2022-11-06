#version 430 core

layout (location = 0) out vec4 FragColor;
layout (location = 1) out vec4 FragColor2;

layout(origin_upper_left) in vec4 gl_FragCoord;

in vec2 vCoord;
in flat int T;

layout (std430, binding = 4) buffer SlotBuffer
    {
        uint fSlot[];
    };

layout (std430, binding = 5) buffer MaskBuffer
    {
        vec4 fMaskColor[];
    };

layout (std430, binding = 6) buffer OpacityBuffer
    {
        float fOpacity[];
    };

layout (std430, binding = 7) buffer ColorVals
    {
        vec4 fColorVals[];
    };

layout (std430, binding = 8) buffer OverLay
    {
        vec4 fOverlay[];
    };

layout (std430, binding = 9) buffer GreyScale
    {
        uint fGreyScale[];
    };


uniform sampler2D tex[32];
uniform float ShadowVal = 0;

void main(){

    float Max;
    vec4 backcolor;
    ivec2 backsize = textureSize(tex[31],0);

    FragColor = texture(tex[fSlot[T]],vCoord);
    backcolor = texture(tex[31],vec2(gl_FragCoord.x / backsize.x, 1 - (gl_FragCoord.y / backsize.y)));


    if (FragColor == fMaskColor[T] || FragColor.w == 0){
        discard;
    }
    else{

        if (fGreyScale[T] == 1) {
            Max = (0.2126 * FragColor.x + 0.7152 * FragColor.y + 0.0722 * FragColor.z);
            FragColor = vec4(Max,Max,Max,FragColor.w);
        }

        FragColor.x = FragColor.x * fColorVals[T].x;
        FragColor.y = FragColor.y * fColorVals[T].y;
        FragColor.z = FragColor.z * fColorVals[T].z;

        if (fOverlay[T].xyz != vec3(0,0,0)){
            FragColor.x = FragColor.x + (fOverlay[T].x * fOverlay[T].w);
            FragColor.y = FragColor.y + (fOverlay[T].y * fOverlay[T].w);
            FragColor.z = FragColor.z + (fOverlay[T].z * fOverlay[T].w);    
        }

        
        FragColor.w = FragColor.w * fOpacity[T];
        // backcolor = backcolor * (1-FragColor.w);
        // FragColor = FragColor + vec4(vec3(backcolor),0);


    }
    

}
