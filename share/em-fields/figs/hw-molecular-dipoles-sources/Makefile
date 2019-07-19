# See notes.txt for notes on how I did this.

default:
	povray Height=6000 Width=6000 hw-molecular-dipoles.pov
	convert hw-molecular-dipoles.png hw-molecular-dipoles-bitmap.jpg
	make clean

preview:
	povray Height=1000 Width=1000 hw-molecular-dipoles.pov && display hw-molecular-dipoles.png
	make clean

clean:
	rm hw-molecular-dipoles.png
