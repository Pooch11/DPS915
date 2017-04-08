#pragma once
#include<map>
#include <vector>
#include <string.h>
#include <string>
#include <sstream>
#include <stdlib.h>
#include <fstream>
#include <cstdlib>
#include <iterator> 
#include <iostream>
#include <cuda_runtime.h>
#include "device_launch_parameters.h" 
using namespace std;

class WordProcessor {
private:
	map<string, string> codex; //Words are stored in Key / Value pair for translation and easier access
	char* arrayOfWords;
public:
	WordProcessor();
	WordProcessor(string inString); //takes in a string to init codex
	WordProcessor(const char* diction); //takes in a whole file for multiple words entry
	~WordProcessor();
	void lookup(string& fileLine);
	void replace(string, string&);
	map<string, string> giveCodex() {
		return codex;
	}
	// Split functions created from StackExchange assistance
	 vector<string> split(const string &s, char delim) {
		std::vector<std::string> elems;
		split(s, delim, back_inserter(elems));
		return elems;
	}

	 void split(const string &s, char delim, back_insert_iterator<vector<string>> out) {
		std::stringstream ss;
		ss.str(s);
		string token;
		while (getline(ss, token, delim)) {
			*(out++) = token;
		}

	}

	 char* splitToArray(string fileLine) {
		 vector<string> tokens = split(fileLine, ' ');
		 char* hold ;
		 for (auto i = tokens.begin(); i != tokens.end(); i++) {
			 //strcpy( hold, const_cast<char*>( tokens[i].c_str() ) );

			 strcat(arrayOfWords, hold);
		 }
		 return arrayOfWords;
	 }
};