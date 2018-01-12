#include "Symbol.h"


Symbol::Symbol()
    :token(UNDEFINED), type(UNDEFINED), address(UNDEFINED), isReference(false)
{
}


Symbol::Symbol(int tokenCode, string tokenVal, int tokenType)
	: token(tokenCode), value(tokenVal), type(tokenType), address(UNDEFINED), isReference(false)
{
}

Symbol::~Symbol()
{
	this->value.clear();
}

string Symbol::getCodeformat() const
{
	if (token == NUM)
		return "#" + value;
	return to_string(address);
}

int Symbol::getSize() const
{
    if (type == REAL && !isReference)
		return floatSize;
    else if(type == INTEGER || isReference) 
        return intSize;
    return UNDEFINED;
}

bool Symbol::operator==(const Symbol & other) const
{
	bool tokenComparison = other.token == this->token || other.token == ID;
	bool valueComparison = other.value.compare(this->value) == 0;
	bool typeComparison = other.type == this->type || other.type == UNDEFINED;
    bool referenceComparison = other.isReference == this->isReference;
    bool argumentsComparison = true;
    
    if(other.argumentTypes.size() != this->argumentTypes.size())
    {
        return false;
    }
    else{
        argumentsComparison = std::equal(other.argumentTypes.begin(), other.argumentTypes.end(), this->argumentTypes.begin());
    }
    
	if (tokenComparison && valueComparison && typeComparison && referenceComparison && argumentsComparison) {
		return true;
	}
	return false;
}

ostream & operator<<(ostream & stream, Symbol & symbol)
{
	stream << Symbol::tokenToString(symbol.token)
		<< "\tvalue: " << symbol.value;
	if (symbol.type != Symbol::UNDEFINED) {
		stream << "\ttype: " << Symbol::tokenToString(symbol.type);
	}
	if (symbol.address != Symbol::UNDEFINED) {
		stream << "\taddress: " << symbol.address;
	}
	if (symbol.isReference != false) {
        stream << "\treference";
    }
    if( symbol.argumentTypes.size() > 0 ){
        stream << "\targTypes: ";
        for(int& type : symbol.argumentTypes){
            stream<<Symbol::tokenToString(type)<<' ';
        }
    }
	return stream;
}

string Symbol::tokenToString(int token)
{
	switch (token) {
	case ID:
		return "Id";
	case VAR:
		return "var";
	case NUM:
		return "num";
	case INTEGER:
		return "int";
	case REAL:
		return "real";
	case FUNCTION:
		return "fun";
	case PROCEDURE:
		return "proc";
	default:
		return "unknown";
	}
}
