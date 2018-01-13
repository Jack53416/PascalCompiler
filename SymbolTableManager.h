#pragma once
#include "Symbol.h"
#include <vector>
#include <algorithm>
#include <string>
#include <limits>
#include <cmath>
#include <iostream>
using namespace std;

class SymbolTableManager
{
public:
	struct TempVarManager {
		int tmpVariableCount = 0;
		string operator()();
	};
	struct AddressAssigner {
		int stackSize = 0;
        int argumentStack = 0; 
        bool isGlobal = false;
		void operator () (Symbol& symbol, bool isArgument);
	};

	struct SymbolTable {
		vector<Symbol> symbols;
		AddressAssigner assignAddress;
		TempVarManager createTempVariable;
        void reset();
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
    void push(const Symbol& symbol);
	void push(int tokenCode, string tokenVal);
	int lookUpPush(int tokenCode, string tokenVal);
	int lookUpPush(int tokenCode, string tokenVal, int tokenType);
	int lookUp(const Symbol& symbol) const;
	int lookUp(const string& value) const;
	int pushTempVar(int type);
    void setLocalScope();
    void setGlobalScope();
    void clearScope();
    int getStackSize();
    bool isInGlobalScope();
	Symbol& operator [] (unsigned int);
	friend ostream& operator << (ostream& stream, SymbolTableManager& symbolTableManager);
	void assignFreeAddress(Symbol& symbol, bool isArgument);

};

