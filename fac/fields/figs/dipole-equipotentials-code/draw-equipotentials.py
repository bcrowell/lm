#!/usr/bin/python3

# Based on code by Wikimedia Commons users Zureks and Geek3, CC0 license,
# https://commons.wikimedia.org/wiki/File:Equipotential_by_Zureks.png .
# Modified by B. Crowell.

import matplotlib
matplotlib.use('SVG')

import numpy as np
from matplotlib import pyplot

w, h = 1047, 1047
xmax = 4.00 
ymax = xmax * float(h) / float(w)
vmax = 0.78
y0 = 1.0
nlevels = 21
levels = np.linspace(-vmax, vmax, nlevels)
X, Y = np.mgrid[-xmax:xmax:250j, -ymax:ymax:800j]

# potential of two point charges
V  = 1.0 / np.maximum(np.sqrt(X**2 + (Y - y0)**2), 1e-2)
V -= 1.0 / np.maximum(np.sqrt(X**2 + (Y + y0)**2), 1e-2)

# rescale potential globally to make contour areas similar
V = (np.sqrt(1 + V * V) - 1) / V

pyplot.figure(figsize=(w/90., h/90.))
cont = pyplot.contour(X, Y, V, levels=levels, colors=['black'], linestyles='dashed')

pyplot.xticks([]), pyplot.yticks([])
pyplot.gca().set_aspect(aspect='equal')
pyplot.gca().axis('off')
pyplot.savefig('equipotentials.svg')
