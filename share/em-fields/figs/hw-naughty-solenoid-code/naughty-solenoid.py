 #!/usr/bin/python3

from math import *

from vectorfieldplot import FieldplotDocument,Field,FieldLine

# ... https://github.com/CD3/VectorFieldPlot

# based on https://commons.wikimedia.org/wiki/File:VFPt_cylindrical_coil.svg
# author Geek3, GFDL

size = 0.6
proportion = 4
l = size*proportion
r = size*1.0
exponent = 1.0/2.0 # run with exponent=1 to get a physically correct version

doc = FieldplotDocument('naughty-solenoid')
field = Field({'coils':[[0,0,0,r,l,1]]})
n = 15
for i in range(n):
    a = (0.5 + i) / n
    a = (-1. + 2. * a)
    # ... after this, a ranges approximately from -1 to 1
    a = copysign(abs(a)**exponent,a)
    # unphysical version for pedagogical use, students explain why it's impossible
    # makes field more intense near the walls
    # re copysign, see https://stackoverflow.com/questions/1986152/why-doesnt-python-have-a-sign-function
    a = a*size
    line = FieldLine(field, [0.0, a], directions='both', maxr=15.0)
    doc.draw_line(line, arrows_style={'dist':3, 'offsets':[0., .5, .5, 1.]})
doc.draw_object('path', {'style':'fill:none; stroke:#808080; ' +
    'stroke-width:.06; stroke-linecap:butt', 'd':f'M -{l},-{r} L {l},-{r}'})
doc.draw_object('path', {'style':'fill:none; stroke:#808080; ' +
    'stroke-width:.06; stroke-linecap:butt', 'd':f'M -{l},{r} L {l},{r}'})
doc.write()
