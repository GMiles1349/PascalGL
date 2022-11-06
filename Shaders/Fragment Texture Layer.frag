#version 420 core
out vec4 FragColor;

in vec2 vCoord;

uniform sampler2D Frame;
uniform sampler2D LightMap;

void main() {

    vec4 LightColor;
    FragColor = texture(Frame,vCoord);
    LightColor = texture(LightMap,vCoord);
    FragColor = vec4(LightColor.x + FragColor.x, LightColor.y + FragColor.y, LightColor.z + FragColor.z, LightColor.w);

}