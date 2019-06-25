#!/usr/bin/ruby

require 'gsl'
  # Install ruby-gsl package:
  #   https://github.com/SciRuby/rb-gsl
require 'hsluv' 
  # http://www.hsluv.org
  # https://github.com/hsluv/hsluv-ruby
  # sudo gem install hsluv

$resolution = 20 # a multiplier; typical values are 1 for draft, 5 for medium resolution, 30 for high resolution
$gamma = 2.0 # https://en.wikipedia.org/wiki/Gamma_correction
   # ... bug: seems to have no effect?
$if_color = true # if false, graph the real part as grayscale, -1=black, 1=white

# Graph a complex-valued function such as a spherical harmonic on the sphere,
# with magnitude represented by brightness and phase by hue.
# The function is specified by the function f().
# If $distortion is nonzero, the sphere is drawn sort of unpeeled so you can see the back.

$PI=3.1415926535

$view = 25.0 # angle above equator in degrees
$distortion = 0.0 # over-all control of distortion; 0=none, 0.3 is a moderate amount

# complex-valued function to graph
# returns [mag,arg]
def f(theta,phi)

  # Ylm
  return ylm(1,-1,theta,phi+3.3)

  #return [1.0,16.0*phi] # unphysical, watermelon stripes with no longitudinal variation

  # unphysical, like Ylm but with long variation too tight
  z= ylm(16,16,theta,phi)
  z[0] = z[0]*(Math::sin(theta))**300
  return z


end

# Define a cyclic color map using a lookup table with 12 interpolation points.
# Each entry is [h,s,v] in the hsluv system.
$color_lut = [
  [8,76,60],  # 0
  [20,77,60],  # 1
  [30,78,60],  # 2
  [57,86,69],  # 3
  [94,79,65],  # 4
  [142,67,60],  # 5
  [192,64,60],  # 6
  [235,64,60],  # 7
  [270,64,50],  # 8
  [300,64,60],  # 9
  [327,64,60],  # 10
  [348,64,60]  # 11
]


def ylm(l,m,theta,phi)
  m = m.abs
    # legendre_Plm chokes on negative m; using |m| is OK as long as we omit Condon-Shortley phase and normalization
  mag = GSL::Sf::legendre_Plm(l,m,Math::cos(theta)).abs
  arg = put_in_range(m*phi,2.0*$PI)
  return [mag,arg]
end

def euler(theta)
  return Complex(Math::cos(theta),Math::sin(theta))
end

def clean_up_complex(z)
  if z[0]>=0.0 then return z end
  z[0] = -z[0]
  z[1] = put_in_range(z[1]+$PI,2.0*$PI)
  return z
end

def color(z)
  z = clean_up_complex(z)
  if $if_color then
    hue,saturation,value = complex_to_hsluv(z)
    r,g,b = Hsluv::hsluv_to_rgb(hue, saturation, value)
    return "rgb <#{r}, #{g}, #{b}>"
  else
    # Re(z)=-1 gives black, Re(z)=1 gives white
    v = mag_arg_to_value(z)
    v = 0.5*(1.0+v) # nominal range of 0 to 1
    if v<0.0 then v=0.0 end
    if v>1.0 then v=1.0 end
    v = v**$gamma
    return "rgb <#{v}, #{v}, #{v}>"
  end
end

def complex_to_hsluv(z)
  mag,arg = z
  value_scale = mag**$gamma
  h,s,v = interpolate_color_lut(arg)

  # fix glitch where blue is too bright and saturated when v is low
  blue = 266.0
  w = 6.0
  if h>blue-w && h<blue+w then
    x = 0.75 # knob to turn the correction up and down, goes 0 to 1
    u = (h-blue)/w # varies from -1 to 1 in this band
    if mag<1.0 then c=1.0-mag else c=0.0 end
    a=Math::cos(u*$PI/2.0) # runs from 0 to 1, measures how much to correct by
    v=v*(1.0-0.1*x*a*c*c)
    s=s*(1.0-1.0*x*a*c)
  end

  return [h,s,v*value_scale]
end

def interpolate_color_lut(arg)
  alpha = 12.0*put_in_range(arg/(2.0*$PI),1.0)
  if alpha==12.0 then alpha=11.999 end
  i = alpha.to_i
  j = (i+1)%12
  x = alpha-i
  h1,s1,v1 = $color_lut[i]
  h2,s2,v2 = $color_lut[j]
  if h2<h1 then h2=h2+360.0 end
  h,s,v = [interpolate(h1,h2,x),interpolate(s1,s2,x),interpolate(v1,v2,x)]
  if h>360.0 then h=h-360.0 end
  return h,s,v
end

def interpolate(a,b,x)
  return a*(1.0-x)+b*x
end

###################################################################

# Make all numbers divisible by 4. (Divisible by 2 so triangulation works, phi divisible by 4 so
# seam is along an edge.)
$n_theta= 8 * $resolution
$n_phi = 12 * $resolution

$radius = 4.0

$scale = 0.3
$background_color = 'Gray'

$graphic = '' # accumulator for the povray code that draws the graphic


###################################################################

def main
  $normalization = 0.0 # greatest magnitude the function ever achieves
  $force_norm= 1.0 # after initial trial run, gets updated to $normalization
  # Estimate normalization, which is probably something like [(l+.5)(l+m)!/(l-m)!]^(1/2).
  # C version of GSL has constants you can use to set the type of normalization, but ruby-gsl doesn't seem to have these,
  # so I don't know what it's actually doing. Just do an empirical estimate.
  # This estimate is actually better than the one we get by doing the real graph, since we use so many
  # points here.
  n = 10000
  (0..(n-1)).each { |i|
    theta = 2.0*$PI*i/n.to_f
    z = f(theta,0.0)
    value = mag_arg_to_value(z).abs
    if value>$normalization then $normalization=value end
  }
  $stderr.print "estimated greatest magnitude achieved by the function = #{$normalization}; normalizing to this\n"
  $force_norm = $normalization
  $normalization = 0

  (0..$n_theta-1).each { |i|
    $stderr.print "i=#{i}/#{$n_theta}\n"
    (0..$n_phi-1).each { |j|
      x = j.to_f/$n_phi
      next if (x-0.25).abs<0.03 && $distortion>0.0
      do_triangle(i,j,    i,j+1,  i+1,j)
      do_triangle(i+1,j,  i,j+1,  i+1,j+1)
    }
  }
  print template().gsub!(/BLANK/,$graphic)
  $stderr.print "actual greatest magnitude achieved by the function = #{$normalization}\n"
end

def mag_arg_to_value(z)
  if $if_color then value=z[0] else value=z[0]*Math::cos(z[1]) end
  return value
end

def do_triangle(i1,j1,i2,j2,i3,j3)
  avg_i = (i1+i2+i3)/3.0
  avg_j = (j1+j2+j3)/3.0
  theta,phi = find_theta_and_phi(avg_i,avg_j)
  z = f(theta,phi)
  z[0] = z[0]/$force_norm
  if z[0]>$normalization then $normalization=z[0] end
  draw_triangle(i1,j1,i2,j2,i3,j3,color(z))
end

def find_theta_and_phi(i,j) # inputs can be integers or floating point
  theta = $PI*i.to_f/$n_theta.to_f
  # phi = 2.0*$PI*(j.to_f+i.to_f/2.0)/$n_phi.to_f
  phi = 2.0*$PI*(j.to_f)/$n_phi.to_f
  return [put_in_range(theta,$PI),put_in_range(phi,2.0*$PI)]
end

def put_in_range(x,max)
  i = (x/max).to_i
  x = x-i*max
  if x>max then x=x-max end
  if x<0 then x=x+max end
  return x
end

def vertex(i,j)
  theta,phi = find_theta_and_phi(i,j)

  # "peeling" so we can see the back
  # parameters:
  phi_peel = 1.1*$distortion # how much to peel, 0=no peeling; this preserves the spherical shape
  tear = 1.0*$distortion # how much to tear it open, 0.0=none; this makes the shape nonspherical
  seam = $PI/2.0 # phi angle at which we tear it open; -pi/2=front, pi/2=back
  #
  phi = phi+seam
  x = 1.0-(phi-$PI).abs/$PI # measures distance from front, 0=front, 1=back
  if phi<$PI then phi=phi/(phi_peel+1.0) end
  if phi>$PI then phi=2.0*$PI-(2.0*$PI-phi)/(phi_peel+1.0) end
  phi = phi-seam
  ct = Math::cos(theta)
  spread = tear*x*ct**2 # how much to pull outward from the seam, 0-1
  r = $radius
  rho = r*(Math::sin(theta)+spread) # distance from z axis

  x = rho*Math::cos(phi)
  y = rho*Math::sin(phi)
  z = r*Math::cos(theta)
  return x,y,z
end

def scalar_mult(s,v)
  return [s*v[0],s*v[1],s*v[2]]
end


def draw_triangle(i1,j1,i2,j2,i3,j3,color)
  p = vertex(i1,j1)
  q = vertex(i2,j2)
  r = vertex(i3,j3)
  s,l = longest_and_shortest_edges(p,q,r)
  #if s!=0.0 && l<2.0*2.0*$PI*$radius/$n_phi then
  if true then
       # s=0 could happen near pole, would make povray give a warning; too long means it's at seam
    $graphic = $graphic + triangle_povray(p,q,r,color)
  else
    # $stderr.print "triangle failed sanity check at i1=#{i1}, j1=#{j1}\n"
  end
end

def point_to_povray(p)
  s = scalar_mult($scale,p)
  return "<#{s[0]},#{s[1]},#{s[2]}>"
end

def longest_and_shortest_edges(p,q,r)
  l = 0.0
  s = 999.0
  x = distance_3d(p,q)
  if x>l then l=x end
  if x<s then s=x end
  x = distance_3d(q,r)
  if x>l then l=x end
  if x<s then s=x end
  x = distance_3d(r,p)
  if x>l then l=x end
  if x<s then s=x end
  return [s,l]
end

def distance_3d(p,q)
  return Math::sqrt((p[0]-q[0])**2+(p[1]-q[1])**2+(p[2]-q[2])**2)
end

def triangle_povray(p,q,r,color)
return <<"POVRAY"
triangle {
  #{point_to_povray(p)}, #{point_to_povray(q)}, #{point_to_povray(r)}
  texture {
    pigment { color #{color} }
  }
}
POVRAY
end

def fatal_error(m)
  $stderr.print m+"\n"
  exit(-1)
end


def template
theta = $view*$PI/180.0
return <<"TEMPLATE"
#version 3.7;
global_settings { assumed_gamma 1.0 }
#include "colors.inc"
background { color #{$background_color} }
camera {
  orthographic // not perspective
  angle 20 // width of camera view, in degrees

  location <0, #{-8*Math::cos(theta)}, #{8*Math::sin(theta)}> // big z means looking down from the pole; big negative x means from in front

  look_at  <0, 0, 0>
  up    <0,0,10>
  right <10,0,0> 
}
BLANK
light_source {
  <0,0,10> color White
  area_light
  <1,0,0>, <0,1,0>, 10, 10 // axis, axis, size, size
}
light_source {
  <0,0,-10> color White
  area_light
  <1,0,0>, <0,1,0>, 10, 10 // axis, axis, size, size
}
light_source {
  <0,10,0> color White
  area_light
  <1,0,0>, <0,0,1>, 10, 10 // axis, axis, size, size
}
light_source {
  <0,-10,0> color White
  area_light
  <1,0,0>, <0,0,1>, 10, 10 // axis, axis, size, size
}
light_source {
  <10,0,0> color White
  area_light
  <0,1,0>, <0,0,1>, 10, 10 // axis, axis, size, size
}
light_source {
  <-10,0,0> color White
  area_light
  <0,1,0>, <0,0,1>, 10, 10 // axis, axis, size, size
}
TEMPLATE
end

# modified from
#   http://martin.ankerl.com/2009/12/09/how-to-create-random-colors-programmatically/
# which he based on https://en.wikipedia.org/wiki/HSL_and_HSV#Converting_to_RGB
# inputs and outputs run 0-1
def hsv_to_rgb(h, s, v)
  if h<0 || h>1 || s<0 || s>1 || v<0 || v>1 then
    fatal_error("h=#{h}, s=#{s}, v=#{v} out of range in hsv_to_rgb")
  end
  if h==1.0 then h=0.99999 end
  if s==1.0 then s=0.99999 end
  if v==1.0 then v=0.99999 end
  h_i = (h*6).to_i
  f = h*6 - h_i
  p = v * (1 - s)
  q = v * (1 - f*s)
  t = v * (1 - (1 - f) * s)
  r, g, b = v, t, p if h_i==0
  r, g, b = q, v, p if h_i==1
  r, g, b = p, v, t if h_i==2
  r, g, b = p, q, v if h_i==3
  r, g, b = t, p, v if h_i==4
  r, g, b = v, p, q if h_i==5
  return [r,g,b]
end

def rescale_hue(h)
  x = 0.5
  h = distort_hue(h,0.83,  -0.1*x) # narrower violet band
  h = distort_hue(h,0.00,   0.1*x) # widen the red
  h = distort_hue(h,0.67,   0.15*x) # widen blue
  h = distort_hue(h,0.50,  -0.05*x) # narrow cyan
  h = distort_hue(h,0.16,   0.02*x) # wider yellow
  return h
end

def distort_hue(h,near,amount)
  # near = color to distort near
  # amount = - to narrow this band, + to widen it
  h = put_in_range(h-near,1.0)
  theta = h*2.0*$PI
  sawtooth = Math::sin(theta)+0.333*Math::sin(theta*2.0) # fiddled with in desmos
  h = h-amount*sawtooth
  h = put_in_range(h+near,1.0)
end


main()
