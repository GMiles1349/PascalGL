#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

// in vec2 vColor;
in vec2 vCoord;

uniform sampler2D tex;
uniform vec3 ColorVals = vec3(1,1,1);
uniform vec3 ColorOverlay = vec3(0,0,0);
uniform int GreyScale = int(0);
uniform float Alpha = 1;
uniform int PixelSize = 1;
uniform float planeWidth;
uniform float planeHeight;

float Max;
vec4 rColor;

void Pixelate();

void main()
{

    FragColor = texture(tex,vCoord);

    if (FragColor == vec4(0,0,0,0)){
        //Nothing
    }
    else {

        if (GreyScale == 1) {
            Max = ((0.2126 * FragColor.x) + (0.7152 * FragColor.y) + (0.0722 * FragColor.z));
            FragColor = vec4(Max,Max,Max,FragColor.w);
        }

            FragColor.x = FragColor.x * ColorVals.x;
            FragColor.y = FragColor.y * ColorVals.y;
            FragColor.z = FragColor.z * ColorVals.z;


        FragColor = FragColor + vec4(ColorOverlay,FragColor.w);

     
    }

    if (PixelSize > 1){
        Pixelate();
    }

}


void Pixelate(){


    float X;
    float Y;
    float fX;
    float fY;

    if ( mod((gl_FragCoord.x),PixelSize) != 0 || mod((gl_FragCoord.y),PixelSize) != 0 ) {
        
        X = int(gl_FragCoord.x - mod(floor(gl_FragCoord.x),PixelSize) + int(PixelSize / 2));
        Y = int(gl_FragCoord.y - mod(floor(gl_FragCoord.y),PixelSize) + int(PixelSize / 2));
        fX = (X / planeWidth);
        fY = (Y / planeHeight);

        FragColor = texelFetch(tex,ivec2(X,Y),0); 
    }


}