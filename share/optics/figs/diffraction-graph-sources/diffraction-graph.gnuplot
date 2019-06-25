set terminal svg
set output "diffraction-graph.svg"
#set key inside left top vertical Right noreverse enhanced autotitles box linetype -1 linewidth 1.000
set samples 300,300
c = 0.3
eps = 0.000001 # avoid 0/0 errors
sinc(x) = sin(x)/x
plot [-10:10] (cos(x)*sinc(c*(x+eps)))**2
