#version 430 core
layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec2 vCoord;
in vec2 vPos;
in flat int p;

uniform int LightCount;
uniform float GlobalLight;
uniform sampler2D tex;
uniform sampler2D lightmap;


layout (std430, binding = 2) buffer CenterBuffer{
    vec2 fCenter[];
};
layout (std430, binding = 3) buffer RadiusBuffer{
    float fRadius[];
};
layout (std430, binding = 4) buffer RadianceBuffer{
    float fRadiance[];
};
layout (std430, binding = 5) buffer ColorBuffer{
    vec4 fColor[];
};

void main(){

    float DistX;
    float DistY;
    float TotalDist;
    float Ratio;
    vec4 texcolor;
    vec4 orgcolor;
    vec4 fullcolor;
    float textotal;
    float FragTotal;

    texcolor = texture(tex,vCoord);
    orgcolor = texture(lightmap,vCoord);

    fullcolor = orgcolor * (1/GlobalLight);

    DistX = abs(gl_FragCoord.x - fCenter[p].x);
    DistX = DistX * DistX;
    DistY = abs(gl_FragCoord.y - fCenter[p].y);
    DistY = DistY * DistY;
    TotalDist = sqrt(DistX + DistY);

    if (TotalDist <= fRadius[p]){
        
        Ratio = 1 - (TotalDist / fRadius[p]);
        Ratio = Ratio * Ratio * fRadiance[p];
        FragColor = fColor[p];
        FragColor.w = (Ratio);

    }
    else{
        discard;    
    }

}
