default:
	./porcupine.rb >porcupine.pov
	povray Height=600 Width=600 porcupine.pov
	convert porcupine.png porcupine-bitmap.jpg
	make clean

clean:
	rm porcupine.png
