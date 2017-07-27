#!/bin/bash

wd=`pwd`
cd ../..

if [ $# -ge 1 ]
then
    in=$1
    shift
    python -m jskparser.jskparser $* $wd/$in
else
    if [ ! -d $wd/out ]; then mkdir -p $wd/out
    else rm $wd/out/*
    fi
    FILES=$wd/input/*
    for f in $FILES
    do
    	echo "python -m jskparser.jskparser $f.java > $wd/out/$(basename $f)"
    	python -m jskparser.jskparser $f > $wd/out/$(basename $f)
    done

    cd $wd
    diff -rBw input out > results.out

    if [ -s results.out ]
    then echo "Tests failed.";
    else echo "Tests passed!";
    fi
fi
