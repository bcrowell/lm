#!/usr/bin/python3

# This is based on the code snippet at https://commons.wikimedia.org/wiki/File:VFPt_dipole.svg .

from math import *
from vectorfieldplot import FieldplotDocument,Field,FieldLine
# ... https://github.com/CD3/VectorFieldPlot

import logging
logging.basicConfig(level=logging.ERROR) # can be DEBUG, INFO, WARNING, or ERROR


doc = FieldplotDocument('dipole', width=800, height=600, commons=True)
k=1 # 3 for first panel
field = Field({'dipoles':[[k,0,1,0]]})
n = 16
for i in range(n):
    a = 2.0 * pi * (0.5 + i) / n
    line = FieldLine(field, [1+k+cos(a), sin(a)],
        maxr=1000, directions='both', pass_dipoles=0)
    doc.draw_line(line, arrows_style=None)
doc.write()
