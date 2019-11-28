#!/usr/bin/ruby


def main
  m = 160 # number of pixels on a side
  w = 0.5 # mm on a side for each pixel
  pixels = ''
  tau = m*0.8 # 1/e fall-off time
  tau = tau*0.1 # comment out this line for close-up scale on time axis
  0.upto(m) { |j|
    x = j*w
    noise = 0.2*(rand(3)+rand(3)+rand(3))
    y = Math.exp(-j/tau)*w
    y = (m-3)*(y*0.9+0.1)
    y = y+noise
    y = m*w-y
    pixels = pixels + "#{pixel(x,y,w)}\n"
  }
  print svg(pixels)
end

def pixel(x,y,w)
  return "<rect style=\"fill:#000000;fill-opacity:1\" width=\"#{w}\" height=\"#{w}\" x=\"#{x}\" y=\"#{y}\" />"
end

def svg(code_for_pixels)
return <<-SVG
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
   width="210mm"
   height="297mm"
   viewBox="0 0 210 297"
   version="1.1"
   id="svg8"
   inkscape:version="0.92.3 (2405546, 2018-03-11)"
   sodipodi:docname="pixel.svg">
  <defs
     id="defs2" />
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="0.35"
     inkscape:cx="-100"
     inkscape:cy="560"
     inkscape:document-units="mm"
     inkscape:current-layer="layer1"
     showgrid="false"
     inkscape:window-width="1280"
     inkscape:window-height="996"
     inkscape:window-x="0"
     inkscape:window-y="0"
     inkscape:window-maximized="1" />
  <metadata
     id="metadata5">
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
#{code_for_pixels}
  </g>
</svg>
SVG
end

main

