#pragma once
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
using namespace std;

class WordProcessor {
private:
	map<string, string> codex; //Words are stored in Key / Value pair for translation and easier access
public:
	WordProcessor();
	WordProcessor(string inString); //takes in a string to init codex
	WordProcessor(const char* diction); //takes in a whole file for multiple words entry
	~WordProcessor();
	bool lookup(string& fileLine);
	void replace(string, string&);

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
};