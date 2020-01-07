require 'chunky_png'
  # ubuntu package ruby-chunky-png

$PI=3.1415926535


$default_width = 614 # 52 mm at 300 dpi
$bg_color = ChunkyPNG::Color::rgb(222,222,222)


def main
  w = $default_width
  h = w
  image = ChunkyPNG::Image.new(w,h,$bg_color)
  lambda = 30.0
  k0 = 2.*$PI/lambda # magnitude of wavevector on incident side
  bdy = 56.7*$PI/180.0 # angle of bdy
  n = 1.55 # index of refr
  b = 0.13*w # width of beam
  snell = 39.7*$PI/180.0 # calc -e "asin((56.7 deg)/1.55)/(1 deg)"
  theta_t = $PI/2.0+bdy-snell
  theta_r = 2*bdy-$PI*0.5
  $stderr.print "theta_t=#{theta_t} theta_r=#{theta_r}\n"
  diffuseness = 10
  max_amp = 0.0
  0.upto(1) { |trial|
  0.upto(w-1) { |x|
    0.upto(h-1) { |y|
      tot = 0.0
      beta = Math::tan(bdy)
      gamma = Math::tan(theta_t)
      u = x-w/2.0
      v = -(y-h/2.0)
      # find coords flipped across bdy
      th = Math::atan2(v,u)
      r = Math::sqrt(u**2+v**2)
      th2 = bdy + (bdy-th)
      uf = r*Math::cos(th2)
      vf = r*Math::sin(th2)
      beyond =  (th>bdy or th<-$PI+bdy)
      mask = true
      0.upto(2) { |wave|
        # 0=incident, 1=reflected, 2=transmitted
        if wave==0 then
          a = 1.0
	  theta = $PI/2.0
          k = k0
          mask = ((u>-b and u<b) and not beyond)
          edge = min(u+b,b-u)
        end
        if wave==1 then
          a=0.4 # not realistic, just chosen to make the reflected wave faint but somewhat visible
          theta = $PI/2 # because we'll use the flipped point for phase
          k = k0 # ditto
          mask = ((uf>-b and uf<b) and not beyond)
          edge = min(uf+b,b-uf)
        end
        if wave==2 then # transmitted
          a=1.0 
          theta = theta_t
          k = k0*n
          # point where this ray passed through bdy
          ub = (gamma*u-v)/(gamma-beta)
          vb = beta*ub
          mask = (beyond and (ub>-b and ub<b))
          edge = min(ub+b,b-ub)
        end
        if not mask then next end
        kx = k*Math::cos(theta)
        ky = k*Math::sin(theta)
        if wave==0 then phase = kx*u+ky*v end
        if wave==1 then phase = kx*uf+ky*vf end # should it be inverted?
        if wave==2 then
          db = Math::sqrt((u-ub)**2+(v-vb)**2) # distance traveled through medium 2
          phase = k0*vb+db*k
        end # not right
        # ---
        d = 1.0
        if edge<0.0 then $stderr.print "edge<0"; exit end
        if edge<diffuseness then d = Math::sin(0.5*$PI*edge/diffuseness) end
        tot = tot+a*d*Math::cos(phase)
      }
      tot = 0.77*tot
      if trial==0 then
        if abs(tot)>max_amp then max_amp=tot end
      else
        tot=tot/max_amp
        if beyond then tot=tot+0.1 else tot=tot-0.1 end # transmitting medium is lighter in color
        ampl = 0.5*(1+linearize((tot+0.1)/1.2)) 
        image[x,y] = color(ampl)
      end
    }
  }
  }
  #$stderr.print "max_amp=#{max_amp}, should be 1\n"
  image.save("refraction-simulation.png")
  image.save("temp.png") # another copy, so makefile can automatically display it
end

def noise_func(x)
  return Math::cos(x)+Math::cos(1.1*x)+Math::sin(1.22*x)+Math::cos(1.29*x+1.0)+Math::cos(1.37*x+2.0)
end

def min(a,b)
  if a<b then return a else return b end
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
