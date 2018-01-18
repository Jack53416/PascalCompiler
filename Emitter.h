#pragma once
#include <fstream>
#include <sstream>
#include <string>
#include <iomanip>
#include <iostream>
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
    static const unsigned int normalColWidth = 11;
	static const unsigned int debugSpacing = 10;
    
	Emitter(const char* filepath);
	~Emitter();
    labelPrinter getLabel;
    
	void switchTarget(TargetType target);
	void putBufferIntoFile();
    string formatLine(const string & label, const string & opcode, const string & args, const string & debugArgs) const;
	string formatLine(const string & label) const;
	string formatLine(const string & opcode, const string & args, const string & debugArgs) const;
	void emitError(const string & error, unsigned int lineNumber) const;
	void emitWarning(const string & warning, unsigned int lineNumber) const;
    
    Emitter &operator << (const string & value);
};

