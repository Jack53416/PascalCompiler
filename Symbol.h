#pragma once
#include "parser.hpp"
#include <string>
#include <limits>
#include <iostream>

using namespace std;

class Symbol
{
public:
	int token;
	string value;
	int type;
	int address;

	Symbol();
	Symbol(int tokenCode, string tokenVal, int tokenType);
	~Symbol();
	string getCodeformat() const;
	bool operator == (const Symbol& other)const;
	friend ostream & operator << (ostream & stream, Symbol & symbol);

	static const int UNDEFINED = numeric_limits<int>::max();
	static string tokenToString(int token);
};

