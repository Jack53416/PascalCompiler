#pragma once
#include "global.hpp"
#include <vector>
#include <algorithm>
#include <string>
#include <limits>
#include <iostream>
using namespace std;

class SymbolTableManager
{
public:
    static const int UNDEFINED = numeric_limits<int>::max(); 
    static const int intSize = 4;
    static const int floatSize = 8;
	struct Symbol {
		int token;
		string value;
		int type;
        int address;
		Symbol(){}
		Symbol(int tokenCode, string tokenVal, int tokenType)
			: token(tokenCode), value(tokenVal), type(tokenType), address(UNDEFINED) {}
		~Symbol() {
			this->value.clear();
		}
		string getCodeformat(){
            if(token == NUM)
                return "#" + value;
            return to_string(address);
        }
		bool operator == (const Symbol& other)const {
			bool tokenComparison = other.token == this->token || other.token == ID;
			bool valueComparison = other.value.compare(this->value) == 0;
			bool typeComparison = other.type == this->type || other.type == UNDEFINED;
			if (tokenComparison && valueComparison && typeComparison) {
				return true;
			}
			return false;
		}
        friend ostream & operator << (ostream & stream, Symbol & symbol) {
			stream << SymbolTableManager::tokenToString(symbol.token)
                   << "\tvalue: " << symbol.value;
            if(symbol.type != UNDEFINED){
                stream << "\ttype: " << SymbolTableManager::tokenToString(symbol.type); 
            }
            if(symbol.address != UNDEFINED){
                stream << "\taddress: " << symbol.address;
            }
            return stream;
            
		};
	};
    
    struct tempVarManager{
        int tmpVariableCount = 0;
        string operator()(){
            int currentIdx = tmpVariableCount;
            tmpVariableCount++;
            return "$t" + to_string(currentIdx);
        }
    };
    struct AddressGiver{
        int stackSize = 0;
        void operator () (Symbol& symbol){
            int freeAddress = stackSize;
            if(symbol.type == UNDEFINED){
                throw std::invalid_argument("Symbol type is undefined! address can't be assigned!");
            }
            if(symbol.type == REAL)
                stackSize += floatSize;
            else
                stackSize += intSize;
            symbol.address = freeAddress;
        }
    };

private:
	vector<Symbol> symbolTable;
	SymbolTableManager();
	SymbolTableManager(SymbolTableManager& );
	void operator = (SymbolTableManager& );
    tempVarManager getTempValue;
public:
	static SymbolTableManager& getInstance();
    static string tokenToString(int token);
	~SymbolTableManager();
	void push(int tokenCode, string tokenVal);
	int lookUpPush(int tokenCode, string tokenVal);
    int lookUpPush(int tokenCode, string tokenVal, int tokenType);
	int lookUp(const Symbol& symbol) const;
    int pushTempVar(int type);
	Symbol& operator [] (unsigned int);
    friend ostream& operator << (ostream& stream, SymbolTableManager& symbolTableManager);
    AddressGiver assignFreeAddress;

};

