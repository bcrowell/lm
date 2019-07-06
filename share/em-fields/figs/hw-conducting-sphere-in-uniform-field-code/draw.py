#!/usr/bin/python3

# https://commons.wikimedia.org/wiki/File:VFPt_superconductor_ball_E-field.svg
# Original code by Geek3, CC-BY. Modifications by B. Crowell under the same license.

from math import *
from vectorfieldplot import FieldplotDocument,Field,FieldLine
# ... https://github.com/CD3/VectorFieldPlot

scale = 1

doc = FieldplotDocument('hw-conducting-sphere-in-uniform-field', width=600, height=600)
field_direction = [0.0, -1.0]
ball_radius = 1.2*scale
field = Field({'homogeneous':[field_direction],
    'dipoles':[[0, 0, 4*pi*ball_radius**3*field_direction[0], 4*pi*ball_radius**3*field_direction[1]]]})
n = 20
for i in range(n):
    a = -3 + 6 * (0.5 + i) / n
    line = FieldLine(field, [a*scale, 6*scale], maxr=12, pass_dipoles=1)
    if abs((n - 1.) / 2. - i) > 7: off = 4 * [0.5]
    else: off = 4 * [0.25]
    doc.draw_line(line, arrows_style={'min_arrows':2, 'max_arrows':2, 'offsets':off, 'scale':2.0})
# draw the superconducting ball
ball = doc.draw_object('g', {'id':'metal_ball'})
grad = doc.draw_object('radialGradient', {'id':'metal_spot', 'cx':'0.53', 'cy':'0.54',
    'r':'0.55', 'fx':'0.65', 'fy':'0.7', 'gradientUnits':'objectBoundingBox'}, group=ball)
for col, of in (('#fff', 0), ('#e7e7e7', 0.15), ('#ddd', 0.25), ('#aaa', 0.7), ('#888', 0.9), ('#666', 1)):
    doc.draw_object('stop', {'offset':of, 'stop-color':col}, group=grad)
doc.draw_object('circle', {'cx':0, 'cy':0, 'r':str(ball_radius),
    'style':'fill:url(#metal_spot); stroke:#000; stroke-width:0.02'}, group=ball)
doc.write()
