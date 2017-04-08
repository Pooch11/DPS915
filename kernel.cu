#pragma once
#include "WordProcessor.h"
#include <iostream>
#include <string.h>
#include <string>
#include <stdlib.h>
#include <fstream>
#include <cstdlib>
#include <iostream>
#include <iomanip>
#include <iterator>
#include <cstdlib>
#include <cuda_runtime.h>
#include "device_launch_parameters.h" // intellisense on CUDA syntax
#ifndef __CUDACC__
#define __CUDACC__
#endif
#include <device_functions.h>
#define Timing 1
#define Serial 0
#define DEBUG 0
#define CHECK if (errorStatus != cudaSuccess) {std::cout << errorStatus << std::endl;}
typedef struct  {
	int length;
	char* text;
	char* translate;
}Word;

using namespace std;
const int ntpb = 32;

cudaError_t errorStatus = cudaGetLastError();

//Device Functions


//string copy for device
__device__ char * my_strcpy(char *dest, const char *src) {
	int i = 0;
	do {
		dest[i] = src[i];
	} while (src[i++] != 0);
	return dest;
}

//string concatenate for device
__device__ char * my_strcat(char *dest, const char *src) {
	int i = 0;
	while (dest[i] != 0) i++;
	my_strcpy(dest + i, src);
	return dest;
}

//'blackbox' - some device function that would replace text given a position
__device__ void replace_char(char s, char replace , int posBeg, int posEnd) {
			s = replace;
		s++;
}


__global__ void wordSearch(char *pszData, int dataLength, char *pszTarget, int targetLen, int *pFound, Word WA)
{
	int idx = blockDim.x*blockIdx.x + threadIdx.x;
	printf("value = %c, address = %p\n", *pszData, (void *)pszData);
	if (*pFound > idx){
		// only continue if an earlier instance hasn't already been found
		int fMatch = 1;
		//printf("value = %c, address = %p\n", *pszData, (void *)pszData);
		for (int i = 0; i < targetLen; i++){ // we need to look for the next character
			if (pszData[idx + i] != pszTarget[i]) 
				fMatch = 0;
			//replace_char(pszTarget[idx + i], 'a');
			//call to strReplace;
		}
		if (fMatch)
			atomicMin(pFound, idx);
	}
}

void matchingCPU(char *T, int n, char *P, short m,bool *result)
{
int k; //keep track of string length
	for (int x = 0; x < n; x++){
		k = 0;
		for (int i = 0; i < m; i++)
			if (T[x + i] == P[i]) //starting to match char by char?
			++k;
		if (k == (m - 1)) { //character match up to length of pattern
			result[x] = true; //true for this start index
		}
	}

}

__global__ void matchingGPU(const char Target[], const char *Pattern, const int textLen, const int pattLen, volatile bool *result)
{
	extern __shared__ bool blockresults[];
	unsigned int Idx = threadIdx.x +blockDim.x * blockIdx.x; // 1 * 1 +  Idx
	if (Idx < textLen){
		 int k = 0;
		for (int i = 0; i < pattLen; i++) 
			if (Target[Idx + i] == Pattern[i]) 
				__syncthreads();
				++k;
		if (k == (pattLen - 1)) {  //if length we traversed is = to pattlen	
			blockresults[Idx] = true; //record match in an index handled by each separate thread
			__syncthreads();
		}
		result[Idx] = blockresults[Idx];
	}

}//end of kernel


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
	void displayFile(fstream& x) {
		x.clear();
		x.seekg(0, ios::beg);
		string line;
		while (std::getline(x, line)) {
			std::cout << line << std::endl;
		}
		x.clear();
		x.seekg(0, ios::beg);
	}
	//Helper function to display number of matches
	void matchcounter(int numOfResults, bool* h_result) {
		unsigned int matches = 0;
		for (int n = 0; n < numOfResults; n++) {
			if (h_result[n] == true) {
				//std::cout << "Found Match" << std::endl;
				matches++;
			}
			else {
				//std::cout << "No match found" << std::endl;
			}
		}
		cout << "Matches: \n" << matches << endl;
}

	//MAIN
	int main(int argc, char *argv[]){
#if Timing
		std::chrono::steady_clock::time_point ts, te, tmems, tmeme, tsCPU, teCPU, tsGPU, teGPU; //timestart, timeend, timecopy, timeCPU, timeGPU
#endif
		WordProcessor WP;
		
		
		if (argc != 3) {
			std::cerr << "Not enough arguments" << std::endl;
			system("pause");
			exit(3);
		}
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
			fstream fp(fname);
			ofstream _tempfp("out.txt"); // this will be the file we write to
			string checkLine;
			unsigned int noLines = 0;
			if (!fp) {
				std::cout << "Cannot open/read file " << fname << std::endl;
				std::cerr << "Could not open/read file" << endl;
				system("pause");
				exit(1); //could not read
			}
#if Timing
			ts = std::chrono::steady_clock::now();
#endif
			//find size of file for array
			fp.seekg(0, std::ios::end);    // go to the end
			 int dataLen = fp.tellg();
			fp.seekg(0, std::ios::beg); //go to beginning
			//declare host and device arrays
			
			char* h_inputLine = new char[dataLen];
			
			//fill inputLine as buffer
			fp.read(h_inputLine, dataLen);

			//our word or pattern
			int patternsize = 4 ;
			char* h_word = new char[patternsize];

			//DEBUG
			strcpy (h_word, "the");


			int numOfResults = ceil( dataLen - ceil(dataLen%(patternsize )));
			//store our results set all to false - none found
			bool *h_result = (bool *)malloc(numOfResults * sizeof(bool));
			memset(h_result, false, numOfResults *sizeof(bool));

			//holders for DEVICE - dennoted by d_
			char* d_inputLine;
			char* d_word;
			bool* d_result;

			//alloc input and output for later use.
			cudaMalloc((void**)&d_inputLine, dataLen * sizeof(char)); // input line to pass change
			cudaMalloc( (void**)&d_word, patternsize * sizeof(char) ); //input pattern to find
			cudaMalloc((void**)&d_result, numOfResults * sizeof(bool)); //store  matches at which indexes
			CHECK

			cudaMemset((void**)d_result, false, numOfResults * sizeof(bool));
			CHECK
#if Timing 
			tmems = std::chrono::steady_clock::now();
			//copy memory to work HOST to DEVICE
			cudaMemcpy(d_inputLine, h_inputLine, dataLen * sizeof(char), cudaMemcpyHostToDevice);
			tmeme = std::chrono::steady_clock::now();
			reportTime("Memcopy to GPU took ", tmeme - tmems);
#endif
			CHECK
				std::cout << "Matching on CPU: " << std::endl;
#if Timing
			tsCPU = std::chrono::steady_clock::now();
			matchingCPU(h_inputLine, dataLen, h_word, patternsize, h_result);
			teCPU = std::chrono::steady_clock::now();
			reportTime("Finding Words in file CPU took ", teCPU - tsCPU);
#endif
			matchcounter(numOfResults, h_result);

			std::cout << "Matching on GPU: " << std::endl;

			//Grid declaration
			int nb = (dataLen + ntpb - 1) / ntpb;
			int results = dataLen / 32 ;
			dim3 dGrid(nb, 1 );
			dim3 dBlock(nb, 1);
#if Timing tsGPU = std::chrono::steady_clock::now();
#endif		

			matchingGPU << < 1, 1024 >> > (d_inputLine, d_word, dataLen, patternsize, d_result);
			cudaDeviceSynchronize();
			CHECK

#if Timing teGPU = std::chrono::steady_clock::now();
			reportTime("Finding Words in file GPU took ", teGPU - tsGPU);
#endif

			//copy back DEVICE to HOST
			cudaMemcpy(h_result, d_result, numOfResults * sizeof(bool), cudaMemcpyDeviceToHost);
			CHECK

			//outputs
			matchcounter(numOfResults, h_result);
			//cout << "InputLine: \n" << h_inputLine << endl;
			//cout << "Pattern: \n" << h_word << endl;


#if Serial
			bool _modification = false;
			while (std::getline(fp, checkLine)) {
			_modification = WP.lookup(checkLine);
				_tempfp << checkLine;
				if (_modification)
					noLines++;
			}
			std::cout << "Processed " << noLines << " number of lines" << std::endl;
#endif

			if (noLines >= 0) { //number of modified lines 
				fp.close();
				_tempfp.close();
				//remove(fname);
				rename("out.txt", fname);
#if Timing
				te = std::chrono::steady_clock::now();
				reportTime("Program total ", te - ts);
#endif
				
			}
			else { //no changes to file old serial method
				_tempfp.close();
				remove("out.txt");
				fp.close();

				delete h_inputLine;
				delete h_word;
				delete h_result;

				cudaFree(d_inputLine);
				cudaFree(d_word);
				cudaFree(d_result);
				system("pause");
				exit(2); //we were not able to write to file - or no changes to file
			}

			//Delete and Free memory
			delete h_inputLine;
			delete h_word;
			delete h_result;

			cudaFree(d_inputLine);
			cudaFree(d_word);
			cudaFree(d_result);
		}

		system("pause");
		cudaDeviceReset();
		return 0;
	
}
