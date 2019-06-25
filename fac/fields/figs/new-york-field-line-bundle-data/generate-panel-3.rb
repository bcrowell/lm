
x = ''
n = 30
mid_i = n/2.0-0.5
a=5.4*1.05
mid_x = 94
max_x = mid_x+(n-mid_i)*(a+1)-7.5
0.upto(n) { |i|
  u = i-mid_i
  x0 = mid_x+u*a
  y0 = 407
  dx = u
  dy = -393
  k = 0
  0.upto(1000) {
    if rand<0.001 then
      break
    end
    k = k+1
  }
  z = k/1000.0
  dx = dx*z
  dy = dy*z
  if x0+dx<0.0 then
    z = -x0/dx
    dx = z*dx
    dy = z*dy
  end
  if x0+dx>max_x then
    z = (max_x-x0)/dx
    dx = z*dx
    dy = z*dy
  end
  x = x + <<-"FOO"
    <path
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:none;fill-opacity:1;fill-rule:evenodd;stroke:#000000;stroke-width:0.5;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker:none;marker-start:none;marker-mid:none;marker-end:none;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate"
       d="m #{x0},#{y0} #{dx},#{dy}"
       id="pathblah#{i}"
       inkscape:connector-curvature="0" />
  FOO
}

svg = <<-"SVG"
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
   viewBox="0 0 744.09448819 1052.3622047"
   id="svg2"
   version="1.1"
   inkscape:version="0.91 r13725"
   sodipodi:docname="a.svg">
  <defs
     id="defs4" />
  <sodipodi:namedview
     id="base"
     pagecolor="#ffffff"
     bordercolor="#666666"
     borderopacity="1.0"
     inkscape:pageopacity="0.0"
     inkscape:pageshadow="2"
     inkscape:zoom="0.4026631"
     inkscape:cx="165.87247"
     inkscape:cy="194.70884"
     inkscape:document-units="px"
     inkscape:current-layer="layer1"
     showgrid="false"
     inkscape:window-width="1280"
     inkscape:window-height="997"
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
        <dc:title />
      </cc:Work>
    </rdf:RDF>
  </metadata>
  <g
     inkscape:label="Layer 1"
     inkscape:groupmode="layer"
     id="layer1">
    <path
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:none;fill-opacity:1;fill-rule:evenodd;stroke:#d0d0d0;stroke-width:0.625;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:4;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;marker:none;marker-start:none;marker-mid:none;marker-end:none;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate"
       d="m 0.38424765,0.00571965 -0.0718,3.92222005"
       id="path5956-7-4-38-0-11-8-8"
       inkscape:connector-curvature="0"
       sodipodi:nodetypes="cc" />
    <rect
       style="color:#000000;clip-rule:nonzero;display:inline;overflow:visible;visibility:visible;opacity:1;isolation:auto;mix-blend-mode:normal;color-interpolation:sRGB;color-interpolation-filters:linearRGB;solid-color:#000000;solid-opacity:1;fill:#d0d0d0;fill-opacity:1;fill-rule:nonzero;stroke:none;stroke-width:0.875;stroke-linecap:butt;stroke-linejoin:miter;stroke-miterlimit:1;stroke-dasharray:none;stroke-dashoffset:0;stroke-opacity:1;color-rendering:auto;image-rendering:auto;shape-rendering:auto;text-rendering:auto;enable-background:accumulate"
       id="rect6435-3-6"
       width="191.52518"
       height="414.18781"
       x="0"
       y="2.4071574" />
#{x}
  </g>
</svg>
SVG

print svg
