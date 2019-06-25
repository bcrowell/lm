#!/usr/bin/python3
from math import *
from vectorfieldplot import FieldplotDocument,Field,FieldLine
# ... https://github.com/CD3/VectorFieldPlot

print("generating files u.svg, like charges")

# paste this code at the end of VectorFieldPlot 1.0
doc = FieldplotDocument('u', width=800, height=800)
field = Field({'monopoles':[[-1,0,-1], [1,0,-1]]})
doc.draw_charges(field)
for x in [-1, 1]:
    line = FieldLine(field, [x,0], start_v=[x, 0],
        directions='backward')
    doc.draw_line(line)
n = 32
for i in range(n):
    a = 2.0 * pi * (0.5 + i) / n
    line = FieldLine(field, [10.*cos(a), 10.*sin(a)],
        directions='forward')
    doc.draw_line(line)
doc.write()

print("generating files v.svg, opposite charges")

# paste this code at the end of VectorFieldPlot 1.0
doc = FieldplotDocument('v', width=800, height=800)
field = Field({'monopoles':[[-1,0,1], [1,0,-1]]})
doc.draw_charges(field)
n = 16
for i in range(n):
    a = (0.5 + i) / n
    a = 2.0 * pi * a
    line = FieldLine(field, [-1,0], start_v=[cos(a), sin(a)],
        directions='forward')
    doc.draw_line(line)
doc.write()
