require 'chunky_png'
  # ubuntu package ruby-chunky-png
require 'hsluv' 
  # http://www.hsluv.org
  # https://github.com/hsluv/hsluv-ruby
  # sudo gem install hsluv

$PI=3.1415926535

$gamma = 1.5 # https://en.wikipedia.org/wiki/Gamma_correction
             # Should be pretty close to 1, since hsluv is perceptual?

$default_width = 614 # 52 mm at 300 dpi
$bg_color = ChunkyPNG::Color::rgb(222,222,222)

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

def main
  w = $default_width
  h = 100
  type = 'moat'
  if type=='traveling' then
    image = ChunkyPNG::Image.new(w,h,$bg_color)
    freq = 4.0 # spatial frequency
    0.upto(w-1) { |x|
      0.upto(h-1) { |y|
        phase = index_to_phase(x,w,freq)
        image[x,y] = color([1.0,phase])
      }
    }
  end
  if type=='standing' then
    image = ChunkyPNG::Image.new(w,h,$bg_color)
    freq = 4.0 # spatial frequency
    0.upto(w-1) { |x|
      0.upto(h-1) { |y|
        phase1 = index_to_phase(x,w,freq)
        phase2 = index_to_phase((w-1)-x,w,freq)
        a = 0.5*(euler(phase1)+euler(phase2))
        image[x,y] = color([a.magnitude,a.arg])
      }
    }
  end
  if type=='moat' then
    h = (0.8*w).to_i
    image = ChunkyPNG::Image.new(w,h,$bg_color)
    freq = 8.0 # spatial frequency
    r = (w*0.4).to_i
    s = r*0.8 # width of strip
    alpha = 0.5 # aspect ratio of moat
    0.upto(1) { |layer|
      0.upto(w-1) { |x|
        xx = (x.to_f-w/2.0)
        next if xx.abs>r
        theta = Math::acos(xx/r) # 0 to pi
        if layer==1 then theta=2.0*$PI-theta end
        0.upto(h-1) { |y|
          yy = -(y.to_f-h/2.0)
          z = yy-alpha*r*Math::sin(theta) # distance from midline of strip
          if z>-s/2.0 && z<s/2.0 then image[x,y] = color([1.0,8.0*theta]) end
        }
      }
    }
  end
  if type=='reflection' then
    h = 25
    image = ChunkyPNG::Image.new(w,h,$bg_color)
    # https://en.wikipedia.org/wiki/Solution_of_Schr%C3%B6dinger_equation_for_a_step_potential
    k1 = 20
    k2 = k1*0.2
    incident = 0.85
    reflected = -(k1-k2)/(k1+k2) # they have the expression without the -, which seems wrong
    transmitted = incident+reflected # continuous function
    0.upto(w-1) { |x|
      0.upto(h-1) { |y|
        xx = (x-w/2.0)/(w/2.0)
        if xx<0.0 then
          a = incident*euler(k1*xx)+reflected*euler(-k1*xx)
        else
          a = transmitted*euler(k2*xx)
        end
        mag = a.magnitude**0.25 # otherwise it's hard to see the transmitted wave
        image[x,y] = color([mag,a.arg])
      }
    }
  end
  if type=='box' then
    h = (w*0.67).to_i
    image = ChunkyPNG::Image.new(w,h,$bg_color)
    0.upto(w-1) { |x|
      0.upto(h-1) { |y|
        phase1 = index_to_phase(x,w,1.0)
        phase2 = index_to_phase(y,h,1.5)
        image[x,y] = color([Math::sin(phase1)*Math::sin(phase2),0.0]) # OK if mag<0, will get fixed by color()
      }
    }
  end
  if type=='complex_plane' then
    h = w
    image = ChunkyPNG::Image.new(w,h,$bg_color)
    0.upto(w-1) { |x|
      0.upto(h-1) { |y|
        xx = (x.to_f-h/2.0)/(h/2.0)
        yy = -(y.to_f-h/2.0)/(h/2.0)
        r = Math::sqrt(xx*xx+yy*yy)
        # if true then 
        if r<=1.0 then
          arg = Math::atan2(yy,xx)
          image[x,y] = color([r,arg])
        end
      }
    }
  end
  if type=='double_slit' then
    w = $default_width
    h = w
    image = ChunkyPNG::Image.new(w,h,$bg_color)
    barrier_color = ChunkyPNG::Color::rgb(255,255,255)
    # https://en.wikipedia.org/wiki/Solution_of_Schr%C3%B6dinger_equation_for_a_step_potential
    k = 30 # wavenumber
    d = 0.7 # spacing between slits
    y1 = d/2
    y2 = -d/2
    ww = 0.2 # width of slits
    barrier_width = 0.1
    0.upto(w-1) { |x|
      0.upto(h-1) { |y|
        xx = (x-w/2.0)/(w/2.0)
        yy = -(y-h/2.0)/(h/2.0)
        in_barrier = false
        if xx<0.0 then
          a = euler(k*xx)
          if xx>-barrier_width && !((yy-y1).abs<ww/2 || (yy-y2).abs<ww/2) then
            in_barrier = true
          end
        else
          nearest = w
          n = 10
          aa = 0.5*(1/(n-1).to_f) # fake interpolation to make amplitude on r.h.s. comparable to left
          a=0
          0.upto(1) { |slit|
            1.upto(n-1) { |i|
              if slit==0 then ys=y1 else ys=y2 end
              ys = ys+(i-(n/2))*(ww/2.0)/(n/2)
              r = Math::sqrt(xx*xx+(yy-ys)**2)
              if r<nearest then nearest = r end
              a = a+aa*euler(k*r)/Math::sqrt(r+5.0/k) # r+... is to avoid singularity
            }
          }
        end
        if xx>=0 && nearest<barrier_width then
          # fake interpolation
          b = euler(k*xx) # the amplitude it would have had if there had been no barrier
          u = nearest/barrier_width
          u = 0.5*(1.0-Math::cos(u*$PI)) # avoid showing artifacts of discretization near singularities
          # if u<0.1 then u=u*u else u=1.1*u-0.1 end
          u=u*u
          a = b*(1.0-u)+a*u
        end
        if in_barrier then
          image[x,y] = barrier_color
        else
          mag = a.magnitude
          # mag = mag**0.5 # brighten it a little
          if mag<1 then # brighten it a little
            mag2 = 0.5*(1.0-Math::cos(mag**0.5*$PI))
            mag = 0.25*mag+0.75*mag2
          end  
          image[x,y] = color([mag,a.arg])
        end
      }
    }
  end
  image.save("#{type}.png")
  image.save("rainbow.png") # another copy, so makefile can automatically display it
end

def euler(theta)
  return Complex(Math::cos(theta),Math::sin(theta))
end

def index_to_phase(x,w,freq)
  return put_in_range(freq*2.0*$PI*x.to_f/w.to_f,2.0*$PI)
end

def clean_up_complex(z)
  if z[0]>=0.0 then return z end
  z[0] = -z[0]
  z[1] = put_in_range(z[1]+$PI,2.0*$PI)
  return z
end

def color(z)
  z = clean_up_complex(z)
  hue,saturation,value = complex_to_hsluv(z)
  r,g,b = Hsluv::hsluv_to_rgb(hue, saturation, value)
  return ChunkyPNG::Color::rgb((r*255).to_i,(g*255).to_i,(b*255).to_i)
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

def complex_to_hsluv_old(z)
  mag,arg = z
  saturation = 1.0
  value = mag**$gamma

  hue = put_in_range(arg/(2.0*$PI)+0.05,1.0) # put red near zero
  hue = hue**0.84 # blue is about 0.55; force it to be 0.5
  if true then
    z = 1.0-Math::cos(2.0*$PI*(hue-0.20)) # distance from yellow
    saturation = 0.8+0.2*Math::exp(-z*z/0.3)
    hue = rescale_hue_husl(hue)
  end
  return [hue*360.0,saturation*80.0,value*60.0]
end

def hsv_to_color(h,s,v)
  r,g,b = hsv_to_rgb(h,s,v)
  return ChunkyPNG::Color::rgb((r*255).to_i,(g*255).to_i,(b*255).to_i)
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

def put_in_range(x,max)
  i = (x/max).to_i
  x = x-i*max
  if x>max then x=x-max end
  if x<0 then x=x+max end
  return x
end

main()
