#pragma once
#include "WordProcessor.h"
#include <iostream>
#include <string.h>
#include <string>
#include <stdlib.h>
#include <fstream>
#include <cstdlib>
#define Timing 0
#if Timing
#include <chrono>
#include <ctime>
//reportTime function made by Chris Szalwinski
void reportTime(const char* msg, std::chrono::steady_clock::duration span) {
	auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(span);
	std::cout << msg << " took - " << ms.count() << " millisecs" << std::endl;
}
#endif

//Helper function to display - do not use with large files
void displayFile(fstream& x){
	x.clear();
	x.seekg(0, ios::beg);
	string line;
	while (std::getline(x, line)) {
		std::cout << line << std::endl;
	}
	x.clear();
	x.seekg(0, ios::beg);
}

int main(int argc, char *argv[])
{
	#if Timing
		std::chrono::steady_clock::time_point ts, te; //timestart, timeend
	#endif
	WordProcessor WP;
	bool _modification = false;

	if (argc == 3) {
		std::string _testsearch = argv[2];
		if (_testsearch.find(".txt") == string::npos) {
			WP = WordProcessor(_testsearch);
		}
		else {
			WP = WordProcessor(argv[2]);
		}
		//initialize some name and file variables to read and write from
		char* fname = argv[1];
		std::fstream fp(fname); 
		std::ofstream _tempfp("out.txt"); // this will be the file we write to
		std::string checkLine;
		unsigned int noLines = 0;
		if (!fp){
			std::cout << "Cannot open/read file " << fname << std::endl;
			exit(1); //could not read
		}
	#if Timing
		ts = std::chrono::steady_clock::now();
	#endif
		while (std::getline(fp, checkLine)) {
		_modification =  WP.lookup(checkLine);
		 _tempfp << checkLine;
		 if (_modification)
		 noLines++;
		}

		if (noLines > 0) {
			fp.close();
			_tempfp.close();
			remove(fname);
			rename("out.txt", fname);
	#if Timing
			te = std::chrono::steady_clock::now();
			reportTime("Finding Words in file ", te - ts);
	#endif
			std::cout << "Processed " << noLines << " number of lines" << std::endl;
		}
		else {
			_tempfp.close();
			remove("out.txt");
			fp.close();
			exit(2); //we were not able to write to file - maybe implement error checking
		}

	}
	getchar();
	return 0;
}