#!/usr/bin/python3

from math import *
from vectorfieldplot import FieldplotDocument,Field,FieldLine
# ... https://github.com/CD3/VectorFieldPlot

print("generating files a.svg")
   
# paste this code at the end of VectorFieldPlot 1.0
s = 1 # scale-down factor
doc = FieldplotDocument('a',unit=100/s)
m = [[-0.3,0,1], [0.5,0,-1], [0,-0.3,-1], [0.1, 1.3,1]]
field = Field({'monopoles':m})
doc.draw_charges(field)
n = 64
k = 4
for i in range(n):
    a = (0.5 + i) / n
    a = 2.0 * pi * a
    for j in range(k):
      line = FieldLine(field, [m[j][0],m[j][1]], start_v=[cos(a), sin(a)],
        directions='forward')
      doc.draw_line(line, arrows_style=None)
doc.write()
