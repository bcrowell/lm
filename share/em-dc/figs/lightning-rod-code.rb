require "matrix"

# This is the code used to simulate the charges in the figure labeled
# 'lightning-rod'. It outputs the results to stdout as svg code that can
# be opened in inkscape.

# To plot the shape of the surface, use lightning-rod-shape.gnuplot

# To reproduce the figure in the book:
#   $dim=3, $coupling=1.0, $n=100, $d2 = 0.0, $d3=0.3, $d4=0.2
#   run once with $initial=true, then once with false

# sanity checks:
# 1. All charges should end up on surface.
# 2. Potential energy should monotonically decrease with time.
# 3. The nearest neighbor distance should have a minimum and maximum value, and these should be not ridiculously dissimilar.
# 4. Should get highest density of charges at locations of highest Gaussian curvature.
# It passes all these checks with $dim=3, fails them with $dim=2...why?

def main
$initial = false # only output svg for initial, random configuration, and then quit; run once with this set to
                # true, then once set to false

$dim = 3 # number of dimensions

$coupling = 1.0 # positive for repulsion

$n = 100 # number of charges

$d2 = 0.0 # amount of football-shaped deformation
$d3 = 0.3 # amount of pear-shaped deformation
$d4 = 0.2 # amount of dog-bone shaped deformation


$path_count = 0 # for svg path ids

srand(0)

# Legendre polynomials:
def p2(x)
  1.5*x*x-0.5
end

def p3(x)
  (2.5*x*x-1.5)*x
end

def p4(x)
  (0.125)*(35.0*x*x*x*x-30.0*x*x+3.0)
end

def surface(cos_theta)
  1.0+$d2*p2(cos_theta)+$d3*p3(cos_theta)+$d4*p4(cos_theta)
end

def cos_theta(v)
  v[0]/v.magnitude
end

def inside?(v)
  v.magnitude <= surface(cos_theta(v))
end

def fff(x)
  sprintf("%5.3f",x)
end


Vector.class_eval do # reopening a class
  def self.zero
    a = []
    1.upto($dim) {
      a.push(0.0)
    }
    return self.elements(a)
  end
  def self.random(scale)
    a = []
    1.upto($dim) {
      a.push(scale*(2.0*rand-1.0))
    }
    return self.elements(a)
  end
end

def unit_normal(p) # find the unit normal to the surface at the point p, which should be close to the surface
  x = p * (surface(cos_theta(p))/p.magnitude) # force it to be on the surface
  eps = 0.001
  # numerically estimate the gradient of r-r_surface
  g = Vector.zero.to_a # gradient
  0.upto($dim-1) { |i|
    a = Vector.zero.to_a
    a[i] = eps
    xx = x+Vector.elements(a)
    g[i] = (surface(cos_theta(xx))-xx.magnitude)/eps
  }
  Vector.elements(g).normalize
end

def perp_part(x,y) # return part of x that is perpendicular to y
  yn = y.magnitude
  x-y*(x.inner_product(y)/(yn*yn))
end

x = [] # positions
v = [] # velocities

0.upto($n-1) {
  begin # pick random points until we find one inside the surface
  xx = Vector.random(1.0+$d2+$d3)
  end until inside?(xx)
  x.push(xx)
  v.push(Vector.zero)
}

def stats(x,iteration)
  xx = (x.sort{ |a,b| a.magnitude/surface(cos_theta(a)) <=> b.magnitude/surface(cos_theta(b))})[0]
  smallest_sr = xx.magnitude/surface(cos_theta(xx))
  cc = []
  far = 999.0*(1+$d2+$d3)
  0.upto($n-1) { |i|
    closest = far
    0.upto($n-1) { |j|
      if i!=j then
        r = x[i]-x[j]
        rm = r.magnitude
        if rm<closest then closest = rm end
      end
    }
    cc[i] = closest
  }
  c = far
  f = -1
  ci = -1
  fi = -1
  0.upto($n-1) { |i|
    if cc[i]<c then c=cc[i]; ci=i end
    if cc[i]>f then f=cc[i]; fi=i end
  }
  e = Math::sqrt(4.*3.141/$n) # estimate minimum spacing
  u = 0.0 # potential energy
  0.upto($n-1) { |i|
    0.upto($n-1) { |j|
      if i!=j then
        u = u+$coupling/((x[i]-x[j]).magnitude)
      end
    }  
  }
  ue = $n*($n-1)*0.5*$coupling/e # estimate lowest possible potential energy
  u = u/ue
  $stderr.print "iteration=#{iteration}, smallest_sr=#{fff(smallest_sr)}, c=#{fff(c)} at ct=#{fff(cos_theta(x[ci]))}, f=#{fff(f)} at ct=#{fff(cos_theta(x[fi]))}, e=#{fff(e)}, U=#{fff(u)}\n"
end

dt = 0.001

$stderr.print "dim=#{$dim}, d2=#{$d2}, d3=#{$d3}, n=#{$n}\n"

1.upto($initial ? 0 : 1000) { |iteration|
  0.upto($n-1) { |i|
    f = Vector.zero # electrical force acting on ith charge
    0.upto($n-1) { |j|
      if j!=i then
        r = x[i]-x[j]
        rm = r.magnitude
        f = f+$coupling*r/(rm**3)
      end
    }
    v = f # pretend a viscous force acts, so that it moves at a speed propto force
    x2 = x[i]+v*dt
    if !(inside?(x2)) then
      if x[i].magnitude < surface(cos_theta(x[i]))-0.001 then
        # we were still some distance away from the surface; just get closer to it in a way that's almost guaranteed to lower U
        q = 1
        while !(inside?(x2))
          q = q*0.9
          x2 = x[i]+q*v*dt
        end
      else
        # we were already pinned at  the surface; move tangentially
        x2 = x[i]+perp_part(v*dt,unit_normal(x[i]))
        # make sure we stay exactly on the surface:
        s = surface(cos_theta(x2))
        x2 = x2*(s/x2.magnitude)
      end
    end
    if !(inside?(x2*0.999)) then $stderr.print "  outside, x2=#{x2}, |x2|=#{x2.magnitude}, s=#{surface(x2[0]/x2.magnitude)}\n"; exit(-1) end
    x[i] = x2
  }
  if iteration%100==0 then stats(x,iteration) end
}


def angle_2d(x)
  #if $dim!=2 then $stderr.print "angle_2d called with $dim!=2"; exit(-1) end
  Math::atan2(x[1],x[0])
end


x = x.sort {|a,b| angle_2d(a) <=> angle_2d(b)}

circles = ''
0.upto($n-1) { |i|
  #$stderr.print fff(x[i].magnitude/surface(x[i][0]/x[i].magnitude)),' ',fff(angle_2d(x[i])*180.0/3.141592),"\n"
  visible = x[i][2]>0 && x[i].magnitude/surface(x[i][0]/x[i].magnitude) > 0.9999
  circles = circles + svg_circle(x[i][0],x[i][1],visible)
}
svg = svg_form()
svg.gsub!(/STUFF/) {circles}

print svg

end

def svg_circle(x,y,visible)
  # x and y go from -1 to 1
  final_scaling = 0.7
  s = 141.7+30.6
  xx = (-30.6+s*(x+1.0)*0.5)*final_scaling
  yy = (34.0-s*0.5+s*(y+1.0)*0.5)*final_scaling
  fill = visible ? "#000000" : "none"
  line_style = visible ? '' : ";stroke-miterlimit:4;stroke-dasharray:1,1;stroke-dashoffset:0"
  $path_count = $path_count + 1
  <<-"SVG"
    <path
       sodipodi:type="arc"
       style="color:#000000;fill:#{fill};fill-opacity:1;stroke:#000000;stroke-width:1;marker:none;visibility:visible;display:inline;overflow:visible;enable-background:accumulate#{line_style}"
       id="path3755-#{$path_count}"
       sodipodi:cx="64.078926"
       sodipodi:cy="212.45007"
       sodipodi:rx="2.4866447"
       sodipodi:ry="2.4866447"
       d="m 66.565571,212.45007 a 2.4866447,2.4866447 0 1 1 -4.97329,0 2.4866447,2.4866447 0 1 1 4.97329,0 z"
       transform="translate(#{xx},#{yy})" />
  SVG
end

def svg_form
  <<-'SVG'
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<!-- Created with Inkscape (http://www.inkscape.org/) -->

<svg
   xmlns:dc="http://purl.org/dc/elements/1.1/"
   xmlns:cc="http://creativecommons.org/ns#"
   xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
   xmlns:svg="http://www.w3.org/2000/svg"
   xmlns="http://www.w3.org/2000/svg"
   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"
   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"
   width="744.09448819"
   height="1052.3622047"
   id="svg2"
   version="1.1"
   inkscape:version="0.48.3.1 r9886"
   sodipodi:docname="New document 1">
  <defs
     id="defs4" />
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="2.613964"
     inkscape:cx="132.85714"
     inkscape:cy="780"
     inkscape:document-units="px"
     inkscape:current-layer="layer1"
     showgrid="false"
     inkscape:window-width="1280"
     inkscape:window-height="998"
     inkscape:window-x="0"
     inkscape:window-y="0"
     inkscape:window-maximized="1" />
  <metadata
     id="metadata7">
    <rdf:RDF>
      <cc:Work
         rdf:about="">
        <dc:format>image/svg+xml</dc:format>
        <dc:type
           rdf:resource="http://purl.org/dc/dcmitype/StillImage" />
        <dc:title></dc:title>
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <g
     inkscape:label="Layer 1"
     inkscape:groupmode="layer"
     id="layer1">
    <rect
       style="fill:#bebebe;fill-opacity:1;stroke:none"
       id="rect2985"
       width="184.25197"
       height="162.85715"
       x="28.571428"
       y="166.6479" />
    STUFF
  </g>
</svg>
  SVG
end

main
