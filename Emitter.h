#pragma once
#include <fstream>
#include <sstream>
#include <string>
using namespace std;

class Emitter
{
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
};

