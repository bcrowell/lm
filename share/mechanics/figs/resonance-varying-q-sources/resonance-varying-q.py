import matplotlib
matplotlib.use('SVG')
import matplotlib.pyplot as plt
import numpy as np
import copy

x_min = 0.0
x_max = 2.0

omega = np.arange(x_min, x_max, 0.025)
e_loq = copy.copy(omega)
e_hiq = copy.copy(omega)

def e(w,q):
  # K&K p. 426, eq. 10.27, average energy
  w0 = 1.0
  gamma = w0/q
  return (1+w*w)/((w0**2-w**2)**2+(w*gamma)**2)

boost = 5.0

for j in range(len(omega)):
  e_loq[j] = e(omega[j],2.0)*boost
  e_hiq[j] = e(omega[j],10.0)

fig, ax = plt.subplots()
width = 52.0/25.4 # inches
fig.set_size_inches(width,width)

ax.set_yscale("log")
ax.set_ylim(0.7,200.0)
ax.set_xticks(np.arange(x_min, x_max, 0.2) , minor=True)
ax.grid(which='both',axis='both')

lines = ax.plot(omega, e_loq)
plt.setp(lines, color='black', linewidth=1.0)
lines = ax.plot(omega, e_hiq)
plt.setp(lines, color='black', linewidth=1.0, linestyle='dashed')


ax.set(xlabel='frequency', ylabel='energy of steady-state vibrations')
ax.grid()

fig.savefig("resonance-width.svg")
plt.show()


