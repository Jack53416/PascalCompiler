#pragma once
#include <fstream>
#include <sstream>
#include <string>
using namespace std;

class Emitter
{
struct labelPrinter{
    unsigned int labelNumber = -1;
    string operator () () {
        labelNumber++;
        return "lab" + to_string(labelNumber);
    }
    string operator () (unsigned int labNr){
        return "lab" + to_string(labNr);
    }
};
private:
	ostream *currentTarget;
	ofstream file;
	stringstream buffer;

public:
	enum TargetType {
		FILE,
		BUFFER
	};
	Emitter(const char* filepath);
	~Emitter();
	void switchTarget(TargetType target);
	void putBufferIntoFile();
	Emitter &operator << (const string & value);
    labelPrinter getLabel;
};

