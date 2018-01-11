#include "SymbolTableManager.h"

SymbolTableManager::SymbolTableManager()
{
	currentTable = &globalTable;
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
	assignFreeAddress(symbol);
	currentTable->symbols.push_back(symbol);
	return currentTable->symbols.size() - 1;
}

void SymbolTableManager::AddressAssigner::operator()(Symbol & symbol)
{
	int freeAddress = stackSize;
	if (symbol.type == Symbol::UNDEFINED) {
		throw std::invalid_argument("Symbol type is undefined! address can't be assigned!");
	}
	if (symbol.type == REAL)
		stackSize += floatSize;
	else
		stackSize += intSize;
	symbol.address = freeAddress;
}

string SymbolTableManager::TempVarManager::operator()()
{
	int currentIdx = tmpVariableCount;
	tmpVariableCount++;
	return "$t" + to_string(currentIdx);
}
