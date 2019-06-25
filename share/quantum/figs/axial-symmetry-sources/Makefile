RESOLUTION = 2400
# ... 2400 seems OK for final version


default:
	povray Height=$(RESOLUTION) Width=$(RESOLUTION) n2.pov
	display n2.png
	povray Height=$(RESOLUTION) Width=$(RESOLUTION) ellipsoid.pov
	display ellipsoid.png
