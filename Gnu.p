set title '<title>'
set ylabel '<yLabel>'
set xlabel '<xLabel>'
set key autotitle columnhead
set term png
set output 'Out.png'
set datafile separator ","
plot 'output.csv' using 1:6 with lines, '' using 1:7 with lines, '' using 1:8 with lines