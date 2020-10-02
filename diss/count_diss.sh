#! /bin/sh

for f in intro prep impl eval concl ; do 
	echo "${f}: $(detex -l chapters/${f}.tex | tr -cd '0-9A-Za-z \n' | wc -w)" ;
done
echo "Total: $(detex -l chapters/*.tex | tr -cd '0-9A-Za-z \n' | wc -w)"

