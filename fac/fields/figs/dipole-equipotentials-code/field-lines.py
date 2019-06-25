#!/usr/bin/python3
from math import *
from vectorfieldplot import FieldplotDocument,Field,FieldLine
# ... https://github.com/CD3/VectorFieldPlot

print("generating file field-lines.svg")

# paste this code at the end of VectorFieldPlot 1.0
doc = FieldplotDocument('field-lines', width=800, height=800)
field = Field({'monopoles':[[0,-1,1], [0,1,-1]]})
n = 16
for i in range(n):
    a = (0.5 + i) / n
    a = 2.0 * pi * a
    line = FieldLine(field, [0,-1], start_v=[cos(a), sin(a)],
        directions='forward')
    doc.draw_line(line)
doc.write()
