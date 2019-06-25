#!/usr/bin/python3
from math import *
from vectorfieldplot import FieldplotDocument,Field,FieldLine
# ... https://github.com/CD3/VectorFieldPlot

print("generating files a.svg")
   
# paste this code at the end of VectorFieldPlot 1.0
doc = FieldplotDocument('a', width=600, height=600, commons=True)
#field = Field({'homogeneous':[[1,3]]})
a = 0.33 # ratio of constant field to current in wire
curr = 0.045 # current in wire
field = Field({'wires':[[0,0,-curr]],'homogeneous':[[a*curr,0]]})
m = 10000 # controls resolution of search for appropriate starting points
# spacing of field lines is dr/di propto 1/B propto r; this integrates to r=(const)exp(const*i)
h = 3 # half-height of square box; is this right?
spacing = 0.01 # extra factor to scale spacing, smaller gives smaller spacing
last_nn = 999
f = 0.2 # .235 was too big
# why is this needed???; bigger f excludes more double-counted lines; if f is too small, uniform
#    spacing at left side is disrupted by extra lines; if too big, disrupted by missing lines
# Presumably this is because the software uses some units for I and B; if it was SI, then I would
# expect this to be 0.5e-7...?
for i in range(m):
  q = (i-m/2.0)*2.0/m # ranges from -1 to 1
  y = q*h
  r = abs(y)+1.0e-6
  if y>0.0:
    s=1.0
  else:
    s= -1.0
  aa = a/f
  nn = (a*r+s*log(r))/spacing
  if floor(nn)>floor(last_nn) and not (y>-1.0/aa and y<0.0) and not (y<0.0 or y>0.225/aa):
    # ... 2nd clause is to avoid drawing the closed lines twice, 3rd is to avoid drawing lines that aren't closed
    print("y=",y,", nn=",nn)
    line = FieldLine(field, [0,y], directions='both')
    doc.draw_line(line, linewidth=1, linecolor='#ff0000', arrows_style=None)
  last_nn = nn
n=20
for i in range(n):
  q = (i-n/2.0)*2.0/n # ranges from -1 to 1
  y = q*h
  line = FieldLine(field, [-2.9,y], directions='both')
  doc.draw_line(line, linewidth=4, arrows_style=None)
doc.write()
