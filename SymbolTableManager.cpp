#include "SymbolTableManager.h"

SymbolTableManager::SymbolTableManager()
{
	currentTable = &globalTable;
    globalTable.assignAddress.isGlobal = true;
    localTable.assignAddress.argumentStack = 8;
}


SymbolTableManager & SymbolTableManager::getInstance()
{
	static SymbolTableManager instance;
	return instance;
}

SymbolTableManager::~SymbolTableManager()
{
	globalTable.symbols.clear();
	localTable.symbols.clear();
}

void SymbolTableManager::push(const Symbol& symbol)
{
    currentTable->symbols.push_back(symbol);
}

void SymbolTableManager::push(int tokenCode, string tokenVal)
{
	Symbol symbol(tokenCode, tokenVal, Symbol::UNDEFINED);
	currentTable->symbols.push_back(symbol);
}


Symbol& SymbolTableManager::operator[](unsigned int position)
{
	return currentTable->symbols.at(position);
}

int SymbolTableManager::lookUpPush(int tokenCode, string tokenVal)
{
	Symbol symbol(tokenCode, tokenVal, Symbol::UNDEFINED);
	int idx = lookUp(symbol);
	if (idx >= 0) {
		return idx;
	}
	currentTable->symbols.push_back(symbol);
	return currentTable->symbols.size() - 1;
}

int SymbolTableManager::lookUpPush(int tokenCode, string tokenVal, int tokenType)
{
	Symbol symbol(tokenCode, tokenVal, tokenType);
	int idx = lookUp(symbol);
	if (idx >= 0) {
		return idx;
	}
	currentTable->symbols.push_back(symbol);
	return currentTable->symbols.size() - 1;
}


int SymbolTableManager::lookUp(const Symbol& symbol) const
{
	auto it = find(currentTable->symbols.begin(), currentTable->symbols.end(), symbol);
	if (it != std::end(currentTable->symbols)) {
		return it - currentTable->symbols.begin();
	}
	return -1;
}

int SymbolTableManager::lookUp(const string& value) const
{
	Symbol symbol(ID, value, Symbol::UNDEFINED);
	return lookUp(symbol);
}

ostream & operator<<(ostream & output, SymbolTableManager & sm)
{
	int idx = 0;
	output << "Global Table:" << endl;
	for (Symbol& symbol : sm.globalTable.symbols) {
		output << idx << "\t" << symbol << endl;
		idx++;
	}
	
	if (sm.localTable.symbols.size() > 0) {
		output << "Local Table:" << endl;
        idx = 0;
		for (Symbol& symbol : sm.localTable.symbols) {
			output << idx << "\t" << symbol << endl;
			idx++;
		}
	}
	return output;
}

int SymbolTableManager::pushTempVar(int type) {
	Symbol symbol;
	if (type != INTEGER && type != REAL) {
		throw std::invalid_argument(Symbol::tokenToString(type) + "is invalid type of temp variable!");
	}
	symbol.token = VAR;
	symbol.value = currentTable->createTempVariable();
	symbol.type = type;
	assignFreeAddress(symbol, false);
	currentTable->symbols.push_back(symbol);
	return currentTable->symbols.size() - 1;
}

void SymbolTableManager::setLocalScope()
{
    currentTable = &localTable;
}

void SymbolTableManager::setGlobalScope()
{
    currentTable = &globalTable;
}

int SymbolTableManager::getStackSize()
{
    return abs(currentTable->assignAddress.stackSize);
}

void SymbolTableManager::assignFreeAddress(Symbol& symbol, bool isArgument)
{
    currentTable->assignAddress(symbol, isArgument);
}

void SymbolTableManager::AddressAssigner::operator()(Symbol & symbol, bool isArgument)
{
	if (symbol.type == Symbol::UNDEFINED && symbol.isReference == false) {
		throw std::invalid_argument("Symbol type is undefined! address can't be assigned!");
	}
	if (symbol.address != Symbol::UNDEFINED){
        return;
    }
    if(isGlobal){
        symbol.address = stackSize;
        stackSize += symbol.getSize();
        return;
        
    }
    if(isArgument){
        symbol.address = argumentStack;
        argumentStack += symbol.getSize();
        return;
    }
    stackSize -= symbol.getSize();
    symbol.address = stackSize;
}

string SymbolTableManager::TempVarManager::operator()()
{
	int currentIdx = tmpVariableCount;
	tmpVariableCount++;
	return "$t" + to_string(currentIdx);
}
