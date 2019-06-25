set terminal svg
set output "battat.svg"
set size square
set parametric
set multiplot
set xrange [-15:15]
set yrange [-15:15]
set samples 300
set border 0
set noxtics
set noytics
plot [0:2*pi] 10*cos(t)+3*(1+.2*sin(t))*cos(12*t),10*sin(t)+3*(1+.2*sin(t))*sin(12*t) ti ""
plot [0:2*pi] 10*cos(t),10*sin(t) ti ""
unset multiplot
