# Makefile for WordFinder
#
GCC_VERSION = 5.2.0
PREFIX = /usr/local/gcc/${GCC_VERSION}/bin/
CC = ${PREFIX}gcc
CPP = ${PREFIX}g++

Wordfinder: Wordfinder.o WordProcessor.o 
	$(CPP) -pg -oWordfinder Wordfinder.o WordProcessor.o

Wordfinder.o : Wordfinder.cpp WordProcessor.cpp WordProcessor.h
	$(CPP) -c -O2 -g -pg -std=c++14 Wordfinder.cpp 

WordProcessor.o : WordProcessor.cpp WordProcessor.h
	$(CPP) -c -O2 -g -pg -std=c++14 WordProcessor.h WordProcessor.cpp
clean:
	rm *.o
