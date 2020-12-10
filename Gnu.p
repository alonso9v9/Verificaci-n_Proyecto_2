set title '<title>'
set ylabel '<yLabel>'
set xlabel '<xLabel>'
set key autotitle columnhead
set term png
set output 'Out.png'
set datafile separator ","
plot 'HELI.CSV' using 1:2 with lines, '' using 1:3 with lines,'' using 1:4 with lines