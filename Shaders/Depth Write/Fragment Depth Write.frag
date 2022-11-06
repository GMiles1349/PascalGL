#version 430 core

out vec4 FragColor;

in vec2 texCoord;

uniform sampler2D lightmap;
uniform sampler2D shadowmap;

vec4 getColor;

void main() {
    getColor = texture(shadowmap, texCoord);

    if ( getColor == vec4(0,0,0,0) || getColor == vec4(1,0,1,1) ){
        gl_FragDepth = 0;
    }
    else {
        gl_FragDepth = 1;
    }

    FragColor = texture(lightmap, texCoord);

}