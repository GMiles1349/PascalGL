#version 430 core
out vec4 FragColor;

layout(origin_upper_left) in vec4 gl_FragCoord;

in vec2 vCoord;

uniform sampler2D tex;
uniform vec3 ColorVals = vec3(1,1,1);
uniform vec3 ColorOverlay = vec3(0,0,0);
uniform int GreyScale = 0;
uniform int MonoChrome = 0;
uniform vec4 MaskColor = vec4(1,0,1,1);
uniform float Opacity = 1;
uniform float Brightness = 1;
uniform int Negative = 0;
uniform vec4 Swizzle = vec4(0,0,0,0);
uniform float blendFactor = 0.1;
uniform float PixelSize;
uniform float planeWidth;
uniform float planeHeight;
uniform float sourceWidth;
uniform float sourceHeight;

float Max;
vec4 rColor;

void Pixelate();
void ApplySwizzle();

void main()
{

    vec4 kernalColor[4];
    int i;
    int blendReduce = 0;

    if (PixelSize <= 1){

        FragColor = texture(tex, vec2(vCoord.x / sourceWidth, (sourceHeight - vCoord.y) / sourceHeight));

        // if (FragColor == vec4(0,0,0,0) || FragColor == MaskColor){
        //     discard;
        // }

        // kernalColor[0] = texelFetch(tex, ivec2(vCoord.x - 1, sourceHeight - vCoord.y - 1), 0);
        // kernalColor[1] = texelFetch(tex, ivec2(vCoord.x + 1, sourceHeight - vCoord.y - 1), 0);
        // kernalColor[2] = texelFetch(tex, ivec2(vCoord.x + 1, sourceHeight - vCoord.y + 1), 0);
        // kernalColor[3] = texelFetch(tex, ivec2(vCoord.x - 1, sourceHeight - vCoord.y + 1), 0);

        // for ( i = 0 ; i < 4 ; i++ ){
        //     if (kernalColor[i] == vec4(0,0,0,0) || kernalColor[i] == MaskColor ){
        //         kernalColor[i] = vec4(0,0,0,0);
        //         blendReduce = blendReduce + 1;
        //     }
        //     else {
        //         kernalColor[i] = kernalColor[i] * blendFactor;
        //     }
        // }

        // FragColor = FragColor + kernalColor[0] + kernalColor[1] + kernalColor[2] + kernalColor[3];
        // FragColor = FragColor / (1 + (blendFactor * (4 - blendReduce)));

    }
    else{
        Pixelate();
    }

    if ( FragColor == MaskColor || FragColor.w == 0 ) {
        FragColor = vec4(0,0,0,0);
    }
    else {


        if (GreyScale == 1) {
            Max = (0.2126 * FragColor.x + 0.7152 * FragColor.y + 0.0722 * FragColor.z);
            FragColor = vec4(Max,Max,Max,FragColor.w);

            if (MonoChrome == 1){

                if ((FragColor.x + FragColor.y + FragColor.z) < 2 ) {
                    FragColor = vec4(0,0,0,1); 
                }
                else {
                    FragColor = vec4(1,1,1,1);
                       
                }

            }
        }

        if (Negative == 1){
            FragColor.x = 1 - FragColor.x;
            FragColor.y = 1 - FragColor.y;
            FragColor.z = 1 - FragColor.z;
        }

        if (Swizzle.w == 1){
            ApplySwizzle();
        }

        FragColor.x = FragColor.x * ColorVals.x;
        FragColor.y = FragColor.y * ColorVals.y;
        FragColor.z = FragColor.z * ColorVals.z;

        FragColor.xyz = FragColor.xyz * Brightness;
        
        FragColor = FragColor + vec4(ColorOverlay,FragColor.w);
        FragColor.w =  Opacity;
    }

}


void Pixelate(){

    int X;
    int Y;
    vec4 PixelColor;

    X = int(floor(vCoord.x * sourceWidth));
    Y = int(floor(vCoord.y * sourceHeight));
    X = int(X - mod(X,PixelSize));
    Y = int(Y - mod(Y,PixelSize));

    FragColor = texelFetch(tex, ivec2( X + int(PixelSize / 2), Y - mod(Y,PixelSize) + int(PixelSize / 2)),0);
}


void ApplySwizzle() {

    vec4 TFrag = FragColor;

    // Red Values
    if (Swizzle.x == 1) {
        FragColor.x = TFrag.y;
    }
    else if (Swizzle.x == 2){
        FragColor.x = TFrag.z;
    }

    // Blue Values
    if (Swizzle.y == 0) {
        FragColor.y = TFrag.x;
    }
    else if (Swizzle.y == 2){
        FragColor.y = TFrag.z;
    }

    // Green Values
    if (Swizzle.z == 0) {
        FragColor.z = TFrag.x;
    }
    else if (Swizzle.z == 1){
        FragColor.z = TFrag.y;
    }


}
