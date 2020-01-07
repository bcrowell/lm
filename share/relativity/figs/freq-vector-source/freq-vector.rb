require 'chunky_png'
  # ubuntu package ruby-chunky-png

$PI=3.1415926535


$default_width = 300
$bg_color = ChunkyPNG::Color::rgb(222,222,222)


def main
  w = $default_width
  h = w
  lambda = 50
  image = ChunkyPNG::Image.new(w,h,$bg_color)
  freq = 4.0 # spatial frequency
  0.upto(w-1) { |x|
    0.upto(h-1) { |y|
      phase = put_in_range((x-y),lambda).to_f/lambda # ranges from 0 to 1
      lin = 1.5 # exponent to make it look more linear to the eye
      ampl = Math::sin(2.0*$PI*phase)
      u = x-w/2
      v = y-w/2
      r = Math::sqrt(u**2+v**2) # distance from center of wave packet
      theta = Math::atan2(v,u)
      longitudinal = r*Math::cos(theta+$PI/4.0)/w
      transverse = r*Math::sin(theta+$PI/4.0)/w
      longitudinal = longitudinal+transverse # make it be emitted and received at definite places, i.e., slant the rectangle into a parallelogram
      env = (3*abs(longitudinal))**3+(8*abs(transverse))**3
      #r = r*(1+0.1*Math::sin(theta)+0.1*Math::sin(3*theta)+0.05*Math::cos(7*theta)) # make shape slightly irregular
      ampl = ampl * Math::exp(-3*env)
      ampl = 0.5*(1+linearize(ampl)) 
      image[x,y] = color(ampl)
    }
  }
  image.save("freq-vector.png")
  image.save("temp.png") # another copy, so makefile can automatically display it
end

def abs(x)
  if x<0.0 then return -x else return x end
end

def linearize(z)
  if z<0 then
    return -linearize(-z)
  else
    return z**1.2
  end
end

def color(z) # z is a real number from 0 to 1
  return ChunkyPNG::Color::rgb((z*255).to_i,(z*255).to_i,(z*255).to_i)
end

def put_in_range(x,max)
  i = (x/max).to_i
  x = x-i*max
  if x>max then x=x-max end
  if x<0 then x=x+max end
  return x
end

main()
