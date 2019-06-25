# based on http://www.gnuplot.info/demo/polar.2.gnu
set clip points
unset border
set dummy t,y
set key inside right top vertical Right noreverse enhanced autotitles box linetype -1 linewidth 1.000
set polar
set samples 160, 160
set xzeroaxis linetype 0 linewidth 1.000
set yzeroaxis linetype 0 linewidth 1.000
set zzeroaxis linetype 0 linewidth 1.000
set xtics axis in scale 1,0.5 nomirror norotate  offset character 0, 0, 0 
set ytics axis in scale 1,0.5 nomirror norotate  offset character 0, 0, 0 
set trange [ 0.00000 : 6.28319 ] noreverse nowriteback
plot 1.0+0.0*(1.5*cos(t)*cos(t)-0.5)+0.3*((2.5*cos(t)*cos(t)-1.5)*cos(t))+0.2*((0.125)*(35.0*cos(t)*cos(t)*cos(t)*cos(t)-30.0*cos(t)*cos(t)+3.0))
