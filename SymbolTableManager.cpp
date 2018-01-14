#include "SymbolTableManager.h"
#include <sstream>

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
    currentTable->symbols.insert({hashFun(symbol.value), symbol});
}

void SymbolTableManager::push(int tokenCode, string tokenVal)
{
	Symbol symbol(tokenCode, tokenVal, Symbol::UNDEFINED);
	currentTable->symbols.insert({hashFun(symbol.value), symbol});
}


Symbol& SymbolTableManager::operator[](lval_Type position)
{
	return currentTable->symbols.at(position);
}

lval_Type SymbolTableManager::lookUpPush(int tokenCode, string tokenVal)
{
	Symbol symbol(tokenCode, tokenVal, Symbol::UNDEFINED);
	lval_Type idx = lookUp(symbol);
	if (idx > 0) {
		return idx;
	}
	currentTable->symbols.insert({hashFun(tokenVal), symbol});
   // cout << "insert: " << symbol << " hash:  " << hashFun(tokenVal) << endl;
    //cout << hashFun(tokenVal) << endl;
	return hashFun(tokenVal);
}

lval_Type SymbolTableManager::lookUpPush(int tokenCode, string tokenVal, int tokenType)
{
	Symbol symbol(tokenCode, tokenVal, tokenType);
    
	lval_Type idx = lookUp(symbol);
	if (idx > 0) {
		return idx;
	}
	currentTable->symbols.insert({hashFun(tokenVal), symbol});
	return hashFun(tokenVal);
}


lval_Type SymbolTableManager::lookUp(const Symbol& symbol) const
{
	auto it = find_if(currentTable->symbols.begin(), currentTable->symbols.end(), [&](pair<size_t, Symbol> val){
        return val.second == symbol;
    });
    
	if (it != std::end(currentTable->symbols)) {
		return it->first;
	}
	return 0;
}

lval_Type SymbolTableManager::lookUp(const string& value) const
{
	Symbol symbol(ID, value, Symbol::UNDEFINED);
	return lookUp(symbol);
}

ostream & operator<<(ostream & output, SymbolTableManager & sm)
{
	int idx = 0;
	output << "global Table:" << endl;
	for (auto& it : sm.globalTable.symbols) {
		output << idx << "\t"/*<< it.first <<"\t"*/ << it.second << endl;
		idx++;
	}
	
	if (sm.localTable.symbols.size() > 0) {
		output << "Local Table:" << endl;
        idx = 0;
		for (auto& it : sm.localTable.symbols) {
			output << idx << "\t" << it.second << endl;
			idx++;
		}
	}
	return output;
}

lval_Type SymbolTableManager::pushTempVar(int type) {
	Symbol symbol;
	if (type != INTEGER && type != REAL) {
		throw std::invalid_argument(Symbol::tokenToString(type) + "is invalid type of temp variable!");
	}
	symbol.token = VAR;
	symbol.value = currentTable->createTempVariable();
	symbol.type = type;
	assignFreeAddress(symbol, false);
	currentTable->symbols.insert({hashFun(symbol.value), symbol});
    //cout << "pushing temp with addr: " << hashFun(symbol.value);
	return hashFun(symbol.value);
}

void SymbolTableManager::setLocalScope()
{
    currentTable = &localTable;
}

void SymbolTableManager::setGlobalScope()
{
    currentTable = &globalTable;
}

string SymbolTableManager::clearScope()
{
    int idx = 0;
    stringstream output;
    
    output << "local Table:" << endl;
    for (auto& it : currentTable->symbols) {
        output << idx << "\t"/*<< it.first <<"\t"*/ << it.second << endl;
        idx++;
    }
    
    currentTable->reset();
    return output.str();
}

int SymbolTableManager::getStackSize()
{
    return abs(currentTable->assignAddress.stackSize);
}

bool SymbolTableManager::isInGlobalScope(){
    return currentTable->assignAddress.isGlobal;
}
void SymbolTableManager::assignFreeAddress(Symbol& symbol, bool isArgument)
{
    currentTable->assignAddress(symbol, isArgument);
}

void SymbolTableManager::SymbolTable::reset()
{
    symbols.clear();
    assignAddress.stackSize = 0;
    createTempVariable.tmpVariableCount = 0;
    
    if(!assignAddress.isGlobal)
        assignAddress.argumentStack = 8;
        
    
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
