# See notes.txt in the directory molecular-dipoles-sources for notes on how I did this.

default:
	povray Height=6000 Width=6000 ammonia.pov
	convert ammonia.png ammonia-bitmap.jpg
	make clean

preview:
	povray Height=1000 Width=1000 ammonia.pov && display ammonia.png
	make clean

clean:
	rm ammonia.png
