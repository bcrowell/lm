
unset border
unset colorbox
unset surface
unset xtics
unset ytics
unset ztics

set pm3d implicit at s
set pm3d scansbackward

set view 120, 10, 1, 1
set samples 200, 200
set isosamples 200, 200
set xrange [-3:3]
set yrange [-3:3]
set zrange [-1.3:1.3]

gamma = 2.2
color(gray) = gray**(1./gamma)
set palette model RGB functions 1-color(gray),1-color(gray),1-color(gray)


# everything is in units of the Bohr radius
# H2 bond length=74 pm; Bohr radius=53 pm; half the bond length, in units of Bohr radius, is .70


 set terminal png transparent nocrop enhanced size 420,320 
 set output 'a.png'
 splot exp(-sqrt((x-.70)**2+y**2))+exp(-sqrt((x+.70)**2+y**2))
 set output 'b.png'
 splot exp(-sqrt((x-.70)**2+y**2))-exp(-sqrt((x+.70)**2+y**2))
 set output 'c.png'
 splot -exp(-sqrt((x-.70)**2+y**2))+exp(-sqrt((x+.70)**2+y**2))
 set output 'd.png'
 splot -exp(-sqrt((x-.70)**2+y**2))-exp(-sqrt((x+.70)**2+y**2))
