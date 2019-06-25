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

merge {
sphere { <0,0,0>,1
    pigment { color rgbt <0.2,0.2,0.2,0.2> }
    scale <0.5,0.5,0.5>
    translate <-0.4,0,0>
}
sphere { <0,0,0>,1
    pigment { color rgbt <0.2,0.2,0.2,0.2> }
    scale <0.5,0.5,0.5>
    translate <0.4,0,0>
}
}
sphere { <0,0,0>,1
    pigment { color rgb <0.0,0.0,0.0> }
    scale <0.03,0.03,0.03>
    translate <-0.4,0,0>
}
sphere { <0,0,0>,1
    pigment { color rgb <0.0,0.0,0.0> }
    scale <0.03,0.03,0.03>
    translate <0.4,0,0>
}
light_source { <-10, 10, 4> color White} // up and above, a little in front
//light_source {
//  <0,0,10> color White
//  area_light
//  <1,0,0>, <0,1,0>, 10, 10
//}
