# See notes.txt for notes on how I did this.

default:
	povray Height=6000 Width=6000 molecular-dipoles.pov
	convert molecular-dipoles.png molecular-dipoles-bitmap.jpg
	make clean

preview:
	povray Height=1000 Width=1000 molecular-dipoles.pov && display molecular-dipoles.png
	make clean

clean:
	rm molecular-dipoles.png
