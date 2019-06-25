#!/usr/bin/python3

# Based on code by Wikimedia Commons users Zureks and Geek3, CC0 license,
# https://commons.wikimedia.org/wiki/File:Equipotential_by_Zureks.png .
# Modified by B. Crowell.

import pickle

import matplotlib
matplotlib.use('SVG')

import numpy as np
from matplotlib import pyplot

fig = pyplot.figure()
ax = fig.add_axes([0, 0, 1, 1])
ax.axis('off')

exec(open("potential.txt").read())

nlevels = 24
levels = np.linspace(-0.5, 0.5, nlevels)
cont = pyplot.contour(a, levels=levels, colors=['black'], linestyles='solid', linewidths=0.3)

fig.savefig('a.svg')
print("wrote a.svg")
