#!/usr/bin/ruby

include Math

x = ''

def bar(x,y,z)
  n = Math.sqrt(x*x+y*y+z*z)
  s = 0.1 # overall scalnig factor
  n = n/s
  x = x/n
  y = y/n
  z = z/n
  r = 0.03 # radius of stem
  h = 0.1 # size of arrowhead compared to length of whole arrow
  k = 2.0 # scaling factor for length
  cap_r = 2.0 # radius of arrowhead's base
  lightness = 0.1
  color = "pigment { rgbt <#{lightness}, #{lightness}, #{lightness}, 0> }"
  result =          "cylinder {\n<#{x}, #{y}, #{z}>, <#{k*(1.0-h)*x}, #{k*(1.0-h)*y}, #{k*(1.0-h)*z}>, #{r*s}\n#{color}\n}"
  result = result + "cone {\n<#{k*(1.0-h)*x}, #{k*(1.0-h)*y},  #{k*(1.0-h)*z}>, #{cap_r*r*s} <#{k*x}, #{k*y}, #{k*z}>, #{0.0} \n#{color}\n}"
  return result
end

def foo(x,y,z)
  return bar(x,y,z)+bar(-x,-y,-z)
end

# vertices, faces, and edges of an octohedron

x = x+foo(1.0,0.0,0.0)
x = x+foo(0.0,1.0,0.0)
x = x+foo(0.0,0.0,1.0)

x = x+foo(1.0,1.0,1.0)
x = x+foo(1.0,1.0,-1.0)
x = x+foo(1.0,-1.0,1.0)
x = x+foo(1.0,-1.0,-1.0)

x = x+foo(1.0,1.0,0.0)
x = x+foo(1.0,0.0,1.0)
x = x+foo(0.0,1.0,1.0)
x = x+foo(1.0,-1.0,0.0)
x = x+foo(-1.0,0.0,1.0)
x = x+foo(0.0,-1.0,1.0)

code = <<-"CODE"
#version 3.7;
global_settings {
        ambient_light rgb <0.200000002980232, 0.200000002980232, 0.200000002980232>
        max_trace_level 15
        assumed_gamma 1.0
}

background { color rgb <0.87,0.87,0.87> }

camera {
	perspective
	location <6,-4,-11>
	angle 1.8
	up <0.605338017703169, -0.633160973095729, 0.48236196623663>
	right <0.722809607772331, 0.691047227700111, 0> 
	direction <-6,4,11> }

light_source {
	<34.4641675666881, -6.16930821906754, -13.8938339481231>
	color rgb <1, 1, 1>
	fade_distance 51.6193694794703
	fade_power 0
	parallel
	point_at <-34.4641675666881, 6.16930821906754, 13.8938339481231>
}

light_source {
	<-8.28951684750327, -21.2083994998063, 20.0190075444017>
	color rgb <0.300000011920929, 0.300000011920929, 0.300000011920929>
	fade_distance 51.6193694794703
	fade_power 0
	parallel
	point_at <8.28951684750327, 21.2083994998063, -20.0190075444017>
}

#default {
	finish {ambient .8 diffuse 1 specular 1 roughness .005 metallic 0.5}
}

union {
#{x}
}
merge {
}
CODE

print code
