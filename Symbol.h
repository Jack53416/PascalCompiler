#pragma once
#include "parser.hpp"
#include <vector>
#include <string>
#include <limits>
#include <iostream>

using namespace std;

class Symbol
{
public:
    static const int intSize = 4;
	static const int floatSize = 8;

	int token;
	string value;
	int type;
	int address;
    bool isReference;
    vector<int> argumentTypes;

	Symbol();
	Symbol(int tokenCode, string tokenVal, int tokenType);
	~Symbol();
    int getSize() const;
	string getCodeformat(bool isGlobal) const;
	bool operator == (const Symbol& other)const;
	friend ostream & operator << (ostream & stream, Symbol & symbol);

	static const int UNDEFINED = numeric_limits<int>::max();
	static string tokenToString(int token);
};

