default:
	make_data >shielding.dat
	vect2gp title='' xlabel='' ylabel='' shielding.dat >shielding.gp
	postprocess <shielding.gp >temp1.gp
	cat preamble.gp temp1.gp >temp.gp
	gnuplot -persist temp.gp >shielding.svg
	rm temp*.gp
