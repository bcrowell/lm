require 'chunky_png'
  # ubuntu package ruby-chunky-png

$PI=3.1415926535

$gamma = 1.5 # https://en.wikipedia.org/wiki/Gamma_correction

$default_width = 614 # 52 mm at 300 dpi
$bg_color = ChunkyPNG::Color::rgb(222,222,222)

def main
  w = $default_width
  h = w
  image = ChunkyPNG::Image.new(w,h,$bg_color)
  m = 4.0
  n = 1.0
  0.upto(2) { |what|
    0.upto(w-1) { |x|
      0.upto(h-1) { |y|
        phase1 = index_to_phase(x,w,m)
        phase2 = index_to_phase(y,h,n)
        a1 = Math::sin(index_to_phase(x,w,m))*Math::sin(index_to_phase(y,h,n))
        a2 = Math::sin(index_to_phase(x,w,n))*Math::sin(index_to_phase(y,h,m))
        if what==0 then a=a1 end
        if what==1 then a=a2 end
        if what==2 then a=0.707*(a1+a2) end
        gray = (128.0*(0.8+a)).to_i
        if gray<0 then gray=0 end
        if gray>255 then gray=255 end
        image[x,y] = ChunkyPNG::Color::rgb(gray,gray,gray)
      }
    }
    image.save("separable#{what}.png")
  }
end

def index_to_phase(x,w,freq)
  return freq*2.0*$PI*x.to_f/w.to_f
end

main()
