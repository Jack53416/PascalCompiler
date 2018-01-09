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
	struct Symbol {
		int token;
		string value;
		int type;
        int address;
		
		Symbol(int tokenCode, string tokenVal, int tokenType)
			: token(tokenCode), value(tokenVal), type(tokenType), address(UNDEFINED) {}
		~Symbol() {
			this->value.clear();
		}
		bool operator == (const Symbol& other)const {
			bool tokenComparison = other.token == this->token;
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
    struct AddressGiver{
        const int intSize = 4;
        const int floatSize = 8;
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
public:
	static SymbolTableManager& getInstance();
    static const char* tokenToString(int token);
	~SymbolTableManager();
	void push(int tokenCode, string tokenVal);
	int lookUpPush(int tokenCode, string tokenVal);
    int lookUpPush(int tokenCode, string tokenVal, int tokenType);
	int lookUp(const Symbol& symbol) const;
	Symbol& operator [] (unsigned int);
    friend ostream& operator << (ostream& stream, SymbolTableManager& symbolTableManager);
    AddressGiver assignFreeAddress;

};

