#pragma once
#include <vector>
#include <algorithm>
#include <string>

using namespace std;

class SymbolTableManager
{
public:
	enum Type {
		INTEGER,
		REAL,
		CHAR,
		STRING,
		LABEL,
		UNDEFINED
	};
	struct Symbol {
		int token;
		string value;
		Type type;
		
		Symbol(int tokenCode, string tokenVal, Type tokenType)
			: token(tokenCode), value(tokenVal), type(tokenType) {}
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
	};
private:
	vector<Symbol> symbolTable;
	SymbolTableManager();
	SymbolTableManager(SymbolTableManager& );
	void operator = (SymbolTableManager& );
public:
	static SymbolTableManager& getInstance();
	~SymbolTableManager();
	void push(int tokenCode, string tokenVal);
	int lookUpPush(int tokenCode, string tokenVal);
    int lookUpPush(int tokenCode, string tokenVal, Type tokenType);
	int lookUp(const Symbol& symbol) const;
	Symbol& operator [] (unsigned int);

};

