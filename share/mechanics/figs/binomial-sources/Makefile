default:
	maxima -q --very-quiet --batch-string="for i thru 101 do (print(float(binomial(100,i-1))));" >a.a
	sed -i 's/$$/,/' a.a
	tr -d '\n' <a.a >b.b
	echo "Now hand-edit b.b, cut and paste into binomial.r, and do R --quiet --slave --no-save --no-restore-data <binomial.r && inkscape plot.svg"



