 #!/usr/bin/python3

# Original source code by Wikimedia Commons user Geek3, GPL v3:
#   https://commons.wikimedia.org/wiki/File:VFPt_sphere-magnets-parallel.svg
# Modified by B. Crowell.

import math
from math import *

from vectorfieldplot import FieldplotDocument,Field,FieldLine

import scipy as sc

# ... https://github.com/CD3/VectorFieldPlot

doc = FieldplotDocument('a', commons=True,
    width=800, height=600)

def spheremagnet_field(xy, p, xy0, R):
    r = xy - xy0
    d = math.sqrt(r[0]**2+r[1]**2)
    if d < R:
        # inside the field is indeed constant
        Fxy = p / (2. * pi * R**3)
    else:
        # outside the field is exatly that of a point-dipole
        Fxy = (3. * sc.dot(p, r) * r - sc.dot(r, r) * p) / (4.*pi*d**5)
    return Fxy

xy0 = sc.array([-1.5, 0.0])
xy1 = sc.array([1.5, 0.0])
p = sc.array([0.5, 0.5]) # magnetization
R = 1.0

field = Field({'custom':[lambda xy: spheremagnet_field(xy, p, xy0, R),
    lambda xy: spheremagnet_field(xy, p, xy1, R)]})

# Start field lines uniformly spaced along a diameter of each sphere.
# The lines on one side coincide, so only do half of the ones for the
# first sphere.
n = 32
first_sphere = True
for xys in [xy0, xy1]:
    for i in range(n):
        if first_sphere and i>=n/2:
            continue
        displ = R * (2 * (i + 0.5) / n - 1) * math.sqrt(0.5)
        p0 = (displ,-displ) + xys
        line = FieldLine(field, p0, directions='both', maxr=7, path_close_tol=0.2,hmax=0.1)
        doc.draw_line(line, arrows_style={'dist':1.8,
            'max_arrows':2, 'offsets':[0.9, 0.3, 0.3, 0.9]})
    first_sphere = False

# draw the spherical magnets
defs = doc.draw_object('defs', {})
grad = doc.draw_object('radialGradient', {'id':'grad', 'r':str(1.2*R),
    'cx':'0', 'cy':str(0.2*R), 'fx':'0', 'fy':str(0.6*R),
    'gradientUnits':'userSpaceOnUse'}, group=defs)
for col, of, opa in [['#ffffff', '0', '0.66'], ['#ffffff', '0.04', '0.6'],
        ['#ffffff', '0.11', '0.4'], ['#ffffff', '0.22', '0.2'],
        ['#555555', '0.7', '0.3'], ['#000000', '1', '0.6']]:
    stop = doc.draw_object('stop', {'stop-color':col, 'offset':of,
        'stop-opacity':opa}, group=grad)
clip = doc.draw_object('clipPath', {'id':'circle_clip'}, group=defs)
doc.draw_object('circle', {'cx':'0', 'cy':'0', 'r':str(R)}, group=clip)

gs = doc.draw_object('g', {'id':'sphere'}, group=defs)
gc = doc.draw_object('g', {'clip-path':'url(#circle_clip)'}, group=gs)
doc.draw_object('circle', {'cx':'0', 'cy':'0', 'r':str(R),
    'style':'fill:#00cc00; stroke:none;'}, group=gc)
doc.draw_object('path', {'d':'M -1,0 A 1,1 0 0 0 1,0 L -1,0 Z',
    'style':'fill:#ff0000; stroke:none;'}, group=gc)
text_N = doc.draw_object('text', {'text-anchor':'middle', 'x':'0', 'y':'0',
    'transform':'translate({},{}) scale({},{})'.format(0, 0.56*R-0.2, 0.05, -0.05),
    'style':'fill:#000000; stroke:none; ' +
    'font-size:12px; font-family:Bitstream Vera Sans;'}, group=gc)
text_N.text = 'N'
text_S = doc.draw_object('text', {'text-anchor':'middle', 'x':'0', 'y':'0',
    'transform':'translate({},{}) scale({},{})'.format(0, -0.56*R-0.2, 0.05, -0.05),
    'style':'fill:#000000; stroke:none; ' +
    'font-size:12px; font-family:Bitstream Vera Sans;'}, group=gc)
text_S.text = 'S'
doc.draw_object('circle', {'cx':'0', 'cy':'0', 'r':str(R),
    'style':'fill:url(#grad); stroke:none;',
    'transform':'rotate(30) scale(1.4,1)'}, group=gc)
doc.draw_object('circle', {'cx':'0', 'cy':'0', 'r':str(R),
     'style':'fill:none; stroke:#000000; stroke-width:0.04;'}, group=gs)

magnet1 = doc.draw_object('use', {'{http://www.w3.org/1999/xlink}href':'#sphere',
    'x':str(xy0[0]), 'y':str(xy0[1])})
magnet2 = doc.draw_object('use', {'{http://www.w3.org/1999/xlink}href':'#sphere',
    'x':str(xy1[0]), 'y':str(xy1[1])})

doc.write()
