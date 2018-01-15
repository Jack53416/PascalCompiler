#pragma once
#include "Symbol.h"
#include <vector>
#include <algorithm>
#include <string>
#include <limits>
#include <unordered_map>
#include <functional>
#include <cmath>
#include <iostream>

#define lval_Type unsigned long int
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
		unordered_map<size_t ,Symbol> symbols;
		AddressAssigner assignAddress;
		TempVarManager createTempVariable;
        void reset();
	};

private:
	SymbolTable *currentTable;
	SymbolTable globalTable;
	SymbolTable localTable;
    
    hash<string> hashFun;
	SymbolTableManager();
	SymbolTableManager(SymbolTableManager&);
	void operator = (SymbolTableManager&);
    lval_Type find (const Symbol &symbol, const SymbolTable *table) const;

public:
	static SymbolTableManager& getInstance();
	~SymbolTableManager();
    void push(const Symbol& symbol);
	void push(int tokenCode, string tokenVal);
	lval_Type lookUpPush(int tokenCode, string tokenVal);
	lval_Type lookUpPush(int tokenCode, string tokenVal, int tokenType);
	lval_Type lookUp(const Symbol& symbol) const;
	lval_Type lookUp(const string& value) const;
	lval_Type pushTempVar(Symbol::GeneralType type);
    void setLocalScope();
    void setGlobalScope();
    string clearScope();
    int getStackSize();
    bool isInGlobalScope();
    string printScope(SymbolTable& symTable, const string & name);
	Symbol& operator [] (lval_Type);
	friend ostream& operator << (ostream& stream, SymbolTableManager& symbolTableManager);
	void assignFreeAddress(Symbol& symbol, bool isArgument);

};

