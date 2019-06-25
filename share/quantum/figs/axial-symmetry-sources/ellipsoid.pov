#version 3.7;
global_settings { assumed_gamma 1.0 }
#include "colors.inc"
background { color rgb <0.867,0.867,0.867> }
camera {
  orthographic // not perspective
  angle 20 // width of camera view, in degrees
  location <0, 0, 10>
  look_at  <0, 0, 0>
  up    <0,10,0>
  right <10,0,0>
}

sphere { <0,0,0>,1
    pigment { color rgbt <0.2,0.2,0.2,0.2> } // match N2
    scale <1.27,1,1> // approximately right for 178Hf, eps2=.251
                     // http://www.wheldon.talktalk.net/thesis/thesis/node10.html
                     // calc -e "x=.251; b=sqrt(pi/5)[(4/3)x+(4/9)x^2+(4/27)x^3+(4/81)x^4]; f=b*(3/4)*sqrt(5/pi); a=.09; u=1+2a; v=1-a; (u-v)/((1/3)u+(2/3)v)"
}
light_source { <-10, 10, 4> color White} // up and above, a little in front
light_source {
  <0,0,10> color White
  area_light
  <1,0,0>, <0,1,0>, 10, 10
}
