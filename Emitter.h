#pragma once
#include <fstream>
#include <sstream>
#include <string>
using namespace std;

class Emitter
{
struct labelPrinter{
    int labelNumber = -1;
    string operator () () {
        labelNumber++;
        return "lab" + to_string(labelNumber);
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

