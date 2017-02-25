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
#include "WordProcessor.h"
using namespace std;
#define DEBUG 0

WordProcessor::WordProcessor() {
	codex[ "something" , "something"];
}

WordProcessor::WordProcessor(string inString) {
	vector<string> keyvalue;

	keyvalue = split(inString, '/');
	codex.insert(make_pair(keyvalue[0], keyvalue[1]));
	#if DEBUG
		cout << "Initiated Codex with " << inString << endl;
	#endif
 }

WordProcessor::WordProcessor(const char* diction) {
	vector<string> keysvalues;
	string line;
	ifstream file(diction);
	while (std::getline (file, line) ) {
		keysvalues = split(line, '/');
		for (auto i = keysvalues.begin(); i != keysvalues.end(); i+=2) {
		#if DEBUG
			cout << *i << " PAIRED WITH " << *(i+1) << endl;
		#endif
			codex.insert(make_pair(*i, *(i + 1)));
		}
	}
	file.close();
}

WordProcessor::~WordProcessor() {
	//do nothing - no new memory
}

bool WordProcessor::lookup(string& fileLine) {
	vector<string> tokens = split(fileLine, ' ');
	bool changed = false;

	for (unsigned int i = 0; i < tokens.size(); i++) {
		auto search = codex.find(tokens[i]); //searching for 1 word
		if (search != codex.end()) {
			replace(tokens[i], fileLine); //replace word in line
			changed = true; //there was at least 1 change
		}
		else {
		#if DEBUG
			cout << "Translations or Word meaning not found for this line" << endl;
		#endif // Debug
		}
	}
	return changed;
}

void WordProcessor::replace(string theToken, string& theLine) {
	//need to upgrade to accomodate ignore of parts of words and spaces on word/token variations
	theLine.replace (theLine.find(theToken), theToken.size() , codex[theToken]);
	#if DEBUG
		cout << "Replaced " << theToken << " with " << codex[theToken] << endl;
	#endif
}

