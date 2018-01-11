#pragma once
#include "Symbol.h"
#include <vector>
#include <algorithm>
#include <string>
#include <limits>
#include <iostream>
using namespace std;

class SymbolTableManager
{
public:
	static const int intSize = 4;
	static const int floatSize = 8;

	struct TempVarManager {
		int tmpVariableCount = 0;
		string operator()();
	};
	struct AddressAssigner {
		int stackSize = 0;
		void operator () (Symbol& symbol);
	};

	struct SymbolTable {
		vector<Symbol> symbols;
		AddressAssigner assignAddress;
		TempVarManager createTempVariable;
	};

private:
	SymbolTable *currentTable;
	SymbolTable globalTable;
	SymbolTable localTable;

	SymbolTableManager();
	SymbolTableManager(SymbolTableManager&);
	void operator = (SymbolTableManager&);

public:
	static SymbolTableManager& getInstance();
	~SymbolTableManager();
	void push(int tokenCode, string tokenVal);
	int lookUpPush(int tokenCode, string tokenVal);
	int lookUpPush(int tokenCode, string tokenVal, int tokenType);
	int lookUp(const Symbol& symbol) const;
	int lookUp(const string& value) const;
	int pushTempVar(int type);
	Symbol& operator [] (unsigned int);
	friend ostream& operator << (ostream& stream, SymbolTableManager& symbolTableManager);
	AddressAssigner assignFreeAddress;

};

