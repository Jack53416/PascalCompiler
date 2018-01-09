#include "SymbolTableManager.h"


SymbolTableManager::SymbolTableManager()
{
}


SymbolTableManager & SymbolTableManager::getInstance()
{
	static SymbolTableManager instance;
	return instance;
}

SymbolTableManager::~SymbolTableManager()
{
	symbolTable.clear();
}

void SymbolTableManager::push(int tokenCode, string tokenVal)
{
	Symbol symbol(tokenCode, tokenVal, UNDEFINED);
	this->symbolTable.push_back(symbol);
}


SymbolTableManager::Symbol& SymbolTableManager::operator[](unsigned int position)
{
	return symbolTable.at(position);
}

int SymbolTableManager::lookUpPush(int tokenCode, string tokenVal)
{
	Symbol symbol(tokenCode, tokenVal, UNDEFINED);
	int idx = lookUp(symbol);
	if (idx >= 0) {
		return idx;
	}
	symbolTable.push_back(symbol);
	return symbolTable.size() - 1;
}

int SymbolTableManager::lookUpPush(int tokenCode, string tokenVal, int tokenType)
{
    Symbol symbol(tokenCode, tokenVal, tokenType);
	int idx = lookUp(symbol);
	if (idx >= 0) {
		return idx;
	}
	symbolTable.push_back(symbol);
	return symbolTable.size() - 1;
}


int SymbolTableManager::lookUp(const Symbol& symbol) const
{
	auto it = find(symbolTable.begin(), symbolTable.end() , symbol);
	if (it != std::end(symbolTable)) {
		return it - symbolTable.begin();
	}
	return -1;
}

ostream & operator<<(ostream & output, SymbolTableManager & sm)
{
    int idx = 0;
	for (SymbolTableManager::Symbol& symbol : sm.symbolTable) {
		 output << idx << "\t" << symbol << endl;
         idx ++;
	}
	return output;
}

const char * SymbolTableManager::tokenToString(int token)
{
    switch(token){
        case ID:
            return "Id";
        case VAR:
            return "var";
        case INTEGER:
            return "integer";
        case REAL:
            return "real";
        case FUNCTION:
            return "function";
        case PROCEDURE:
            return "procedure";
        default:
            return "unknown";
    }
}
