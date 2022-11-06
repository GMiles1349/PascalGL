#version 430 core

layout(origin_upper_left) in vec4 gl_FragCoord;

out vec4 FragColor;

in vec2 sCoord;
in vec2 Center;

uniform sampler2D tex;

float PI = 3.1415;


float atan2(in float y, in float x); 

void main(){
    FragColor = texture(tex,sCoord);
}


float atan2(in float y, in float x){

  float theta;

  if (abs(x) < 0.0000001) {

    if (abs(y) < 0.0000001) {
      theta = 0;
    }
    else if (y > 0) {
      theta = 1.5707963267949;
    }
    else {
      theta = -1.5707963267949;
    }

  }  

  else {
    theta = atan(y / x);
  
    if (x < 0) {

      if (y >= 0) {
        theta = 3.14159265358979 + theta;
      }
      else {
        theta = theta - 3.14159265358979;
      }
    }
  }
    
  return theta;

}