#include "SymbolTableManager.h"
#include <sstream>

SymbolTableManager::SymbolTableManager()
{
	currentTable = &globalTable;
    globalTable.assignAddress.isGlobal = true;
    globalTable.scopeName = "global";
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
    try{
        return currentTable->symbols.at(position);
    }
    catch (const std::out_of_range &ex){
        if( currentTable != &globalTable)
            return globalTable.symbols.at(position);
        else
            throw std::out_of_range("Could not find symbol with key: " + to_string(position));
    }
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
    lval_Type idx = find(symbol, currentTable);
    if (currentTable != &globalTable && idx == 0){
        return find(symbol, &globalTable);
    }
    return idx;
}

lval_Type SymbolTableManager::lookUp(const string& value) const
{
	Symbol symbol(ID, value, Symbol::UNDEFINED);
	return lookUp(symbol);
}

lval_Type SymbolTableManager::find(const Symbol &symbol, const SymbolTable *table) const
{
    auto it = find_if(table->symbols.begin(), table->symbols.end(), [&](pair<size_t, Symbol> val){
        return val.second == symbol;
    });
    
    if (it != std::end(table->symbols)) {
        return it->first;
    }
    
    return 0;
}

string SymbolTableManager::printScope(SymbolTable& symTable)
{
    int idx = 0;
    stringstream output;
    vector<Symbol> sortedSymbols;
    
	output << "Scope: " << symTable.scopeName << endl;
    for (auto & it : symTable.symbols){
        sortedSymbols.push_back(it.second);
        //cout << it.first << '\t' << it.second << endl;
    }
    
    std::sort(sortedSymbols.begin(), sortedSymbols.end(), [&](Symbol val1, Symbol val2){
        if(val1.address != val2.address)
            return val1.address < val2.address;
        return val1.value < val2.value;
    });
    
	for (auto& it : sortedSymbols) {
		output << idx << "\t"/*<< it.first <<"\t"*/ << it << endl;
		idx++;
	}
	output << endl;
	return output.str();
}

ostream & operator<<(ostream & output, SymbolTableManager & sm)
{
	output << sm.printScope(sm.globalTable);
	if (sm.localTable.symbols.size() > 0) {
		output << sm.printScope(sm.localTable);
	}
	return output;
}

lval_Type SymbolTableManager::pushTempVar(Symbol::GeneralType type) {
	Symbol symbol;
    Symbol::GeneralType tempType;
    int simpleType = type.id;
    
    if(type.id == ARRAY){
        simpleType = type.subtype;
    }
    
	if (simpleType != INTEGER && simpleType != REAL) {
		throw std::invalid_argument(Symbol::tokenToString(type.id) + " " + to_string(type.id) + " is invalid type of temp variable!");
	}
	tempType.id = simpleType;
	symbol.token = VAR;
	symbol.value = currentTable->createTempVariable();
	symbol.type = tempType;
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

void SymbolTableManager::setScopeName(string sName)
{
    currentTable->scopeName = sName;
}
string SymbolTableManager::getScopeName()
{
    return currentTable->scopeName;
}
string SymbolTableManager::clearScope()
{
    string result = printScope(localTable);
    currentTable->reset();
    return result;
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
    scopeName = "";
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
    symbol.isLocal = true;
    
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
