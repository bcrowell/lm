default:
	pdflatex maxwell
	pdf2svg maxwell.pdf maxwell.svg
	inkscape --export-area-drawing --export-png=maxwell.png --export-dpi=600 maxwell.svg
	convert -flatten maxwell.png a.pgm
	potrace --svg a.pgm
	mv a.svg maxwell.svg
	rm -f *.pgm *.jpg *.pdf *.aux *.log *.png *~

