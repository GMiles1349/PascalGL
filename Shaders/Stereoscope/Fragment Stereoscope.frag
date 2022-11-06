#version 430 core

out vec4 FragColor;

in float texWidth;
in float texHeight;
in vec2 vCoord;

uniform sampler2D tex;
uniform vec2 OffSet;

void main() {

    vec4 orgColor = texelFetch(tex, ivec2( vCoord.x * texWidth, vCoord.y * texHeight), 0 );
    vec4 newColor = texelFetch(tex, ivec2( (gl_FragCoord.x + OffSet.x), (gl_FragCoord.y + OffSet.y)), 0);

    FragColor = mix(orgColor, newColor, 0.5);

    newColor = texelFetch(tex, ivec2( (gl_FragCoord.x - OffSet.x), (gl_FragCoord.y - OffSet.y)), 0);

    FragColor = mix(orgColor, newColor, 0.5);

}