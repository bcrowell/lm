require 'chunky_png'
  # ubuntu package ruby-chunky-png

$PI=3.1415926535

$gamma = 1.5 # https://en.wikipedia.org/wiki/Gamma_correction

$default_width = 1335 # 113 mm at 300 dpi
$bg_color = ChunkyPNG::Color::rgb(222,222,222)

def main
  want_envelope = true
  w = $default_width
  h = w/4
  image = ChunkyPNG::Image.new(w,h,$bg_color)
  n = 100 # number of fourier components; use 100 for final version, 20 for draft
  k = [] # array of wavenumbers and phases
  srand 1
  broadening = 0.05 # 0.05 gives long coherence length, 0.1 short, 0.2 very short
  k0 = 0.2 # typical wave number in the x direction; use 0.1 for full-panel pix, 0.2 with envelope
  print "components=#{n}, broadening=#{broadening}, coherence length=#{2.0*$PI/(k0*broadening)} pixels\n"
  0.upto(n-1) { |i|
    r1,r2,r3 = r(),r(),rand*2*$PI
    k.push([k0*(1+broadening*r1),k0*broadening*r2,r3]) # kx, ky, phase
  }
  0.upto(w-1) { |x|
    0.upto(h-1) { |y|
      a = 0.0
      0.upto(n-1) { |i|
        kk = k[i]
        a = a+Math::sin(kk[0]*x+kk[1]*y+kk[2])
      }
      a = a/Math::sqrt(n) # make it typically range from -1 to 1
      a = a*0.5
      if want_envelope then a=a*envelope(x-w/2.0,w/5.0)*envelope(y-h/2.0,h/5.0) end
      gray = (128.0*(0.8+a)).to_i
      if gray<0 then gray=0 end
      if gray>255 then gray=255 end
      image[x,y] = ChunkyPNG::Color::rgb(gray,gray,gray)
    }
  }
  image.save("coherence.png")
end

def envelope(x,sd)
  u = x/sd
  u = u*u
  y = Math::exp(-0.5*(u+0.1*u*u*u+0.05*u*u*u*u)) # high-order term is to make it merge visually at edge, no visible artifacts
  return y
end

def r
  return (rand+rand+rand-1.5)*2.0 # approximately normal with unit variance (each term has variance 1/12,
                              # so sum has variance 1/4)
end

main()
