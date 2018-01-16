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
	static const int UNDEFINED = numeric_limits<int>::min();

	struct GeneralType {
		int id;
		int subtype;
		int startIdx;
		int endIdx;
		GeneralType();
		GeneralType(int typeId);
		bool operator == (const GeneralType& other) const;
        bool operator != (const GeneralType & other) const;
		friend ostream & operator << (ostream & stream, GeneralType & type);
	};

	int token;
	string value;
	GeneralType type;
	int address;
	bool isReference;
	bool isLocal;
	vector<GeneralType> argumentTypes;

	Symbol();
	Symbol(int tokenCode, string tokenVal, int tokenType);
	~Symbol();
	int getSize() const;
    string getAddress(bool reference) const;
	string getCodeformat() const;
	void addArgumentType(int typeId);
	bool operator == (const Symbol& other)const;
	friend ostream & operator << (ostream & stream, Symbol & symbol);

	static const int getTypeSize(int type);

	static string tokenToString(int token);
};

