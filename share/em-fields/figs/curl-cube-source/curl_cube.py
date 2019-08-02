import copy,re,math,random

# Writes a.svg, which then needs to be hand-edited.
# Hand editing:
#   Add gray outline of cube.
#   Add semi-transparent white edges at top.
#   Grow.
#   Make lines in back thinner.

def main():
  write_svg()

def write_svg():
  svg_code = """
  <?xml version="1.0" encoding="UTF-8" standalone="no"?>
  <!-- Created with Inkscape (http://www.inkscape.org/) -->
  <svg   xmlns:svg="http://www.w3.org/2000/svg"   xmlns:sodipodi="http://sodipodi.sourceforge.net/DTD/sodipodi-0.dtd"   xmlns:inkscape="http://www.inkscape.org/namespaces/inkscape"  xmlns:xlink="http://www.w3.org/1999/xlink">
  <defs
     id="defs2">
    <marker
       inkscape:stockid="Arrow1Mend"
       orient="auto"
       refY="0.0"
       refX="0.0"
       id="Arrow1Mend"
       style="overflow:visible;"
       inkscape:isstock="true">
      <path
         id="path820"
         d="M 0.0,0.0 L 5.0,-5.0 L -12.5,0.0 L 5.0,5.0 L 0.0,0.0 z "
         style="fill-rule:evenodd;stroke:#000000;stroke-width:1pt;stroke-opacity:1;fill:#000000;fill-opacity:1"
         transform="scale(0.8) rotate(180) translate(12.5,0)" />
    </marker>
  </defs>
  ARROWS
  </svg>
  """.strip()
  arrows = ''
  # outline edges so I can see the outline of the cube:
  for m in range(4):
    u = m/2
    v = m%2
    if False: # not needed with current algorithm, lines naturally land at edges
      arrows = arrows + line_svg(u,v,color="#dd0000")
  n = 10
  e_folds_u = 3.0*1.0314159 # random numbers slightly different from 1 so that arrows aren't hidden behind each other
  e_folds_v = 1.5*1.0271828
  for i in range(n):
    u = line_position(e_folds_u,i,n)
    for j in range(n):
      v = line_position(e_folds_v,j,n)
      if i==n-1 or j==n-1:
        if_arrowhead = True
        color="#000000"
      else:
        if_arrowhead = False
        color="#707070"
      arrows = arrows + line_svg(u,v,if_arrowhead=if_arrowhead,color=color)
  svg_code = re.sub("ARROWS",arrows,svg_code)
  with open("a.svg", 'w') as f:
    f.write(svg_code+"\n")

def line_position(e_folds,i,n):
  a = e_folds/n
  return (math.exp(a*i)-1.0)/(math.exp(a*(n-1))-1.0)

def line_svg(u,v,color="#000000",if_arrowhead=True):
  arrow = """
    <path
       style="opacity:1;vector-effect:none;fill:none;fill-opacity:1;stroke:#000000;stroke-width:0.934384;stroke-opacity:1;ARROWHEAD"
       d="M _X,_Y l _DX,_DY l _DX,_DY" />
  """.strip()
    
  s = 80.0
  cos = math.sqrt(3)/2.0
  sin = 1.0/2.0
  xy_scale = 2.0 # makes it a cube
  x = (-u*cos+v*cos)*xy_scale
  y = (u*sin+v*sin)*xy_scale
  a = copy.copy(arrow)
  a = re.sub("_X",str(x*s),a)
  a = re.sub("_Y",str(y*s),a)
  a = re.sub("_DX",str(0.0),a)
  a = re.sub("_DY",str(-1.0*s),a)
  a = re.sub("#000000",color,a) 
  if if_arrowhead:
    a = re.sub(";ARROWHEAD",";marker-mid:url(#Arrow1Mend)",a)
  else:
    a = re.sub(";ARROWHEAD","",a)
  return a+"\n    "
  
main()
