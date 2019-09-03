 #include "colors.inc"
  background { color Black }
  camera {
        perspective
        location <0,0,-12>
        angle 0
        up <0, 1, 0> * 0.4
        right <1,0,0> * 0.4
        direction <0,0,1>
  }
  sphere {
    <0, 0, 0>, 2
    texture {
      pigment { color White }

    }
  }
  global_settings { ambient_light rgb<0, 0, 0> }
  light_source { 
    // pointlight
    <-100, 0, 0> color White
  }

