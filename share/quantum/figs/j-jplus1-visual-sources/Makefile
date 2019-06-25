RESOLUTION = 600
# ... 2400 seems OK for final version

default:
	./sphere.rb >sphere.pov
	povray Height=$(RESOLUTION) Width=$(RESOLUTION) sphere.pov
	rm sphere.pov
	display sphere.png
