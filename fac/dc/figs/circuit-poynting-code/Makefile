default:
	cc -o poisson poisson.c
	poisson >potential.txt
	draw-equipotentials.py

clean:
	rm -f poisson potential.txt a.svg
