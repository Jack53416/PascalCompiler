#include "Symbol.h"
#include <sstream>


Symbol::Symbol()
    :token(UNDEFINED), type(UNDEFINED), address(UNDEFINED), isReference(false), isLocal(false)
{
}


Symbol::Symbol(int tokenCode, string tokenVal, int tokenType)
	: token(tokenCode), value(tokenVal), type(tokenType), address(UNDEFINED), isReference(false), isLocal(false)
{
}

Symbol::~Symbol()
{
	this->value.clear();
}

string Symbol::getCodeformat() const
{
    stringstream output;
    
	if (token == NUM){
        output << '#' << value;
        return output.str();
    }
    
    if(isReference)
        output << '*';
    if(isLocal){
        output << "BP";
        if(address > 0){
            output << '+';
        }
    }
        
    
    
    output << address;
	return output.str();
}

int Symbol::getSize() const
{
    if (type == REAL && !isReference)
		return floatSize;
    else if(type == INTEGER || isReference) 
        return intSize;
    else if(type == ARRAY){
        try{
            const GeneralType &arrayType = argumentTypes.at(0);
            return (arrayType.endIdx - arrayType.startIdx + 1) * Symbol::getTypeSize(arrayType.id);
        }
        catch(const std::out_of_range &ex){
            std::cerr << "Size error can't calculate size for symbol: " << value << endl; 
        }
    }
    return UNDEFINED;
}

void Symbol::addArgumentType(int typeId)
{
    GeneralType type;
    type.id = typeId;
    type.startIdx = UNDEFINED;
    type.endIdx = UNDEFINED;
    argumentTypes.push_back(type);
}

bool Symbol::operator==(const Symbol & other) const
{
	bool tokenComparison = other.token == this->token || other.token == ID;
	bool valueComparison = other.value.compare(this->value) == 0;
	bool typeComparison = other.type == this->type || other.type == UNDEFINED;
    bool referenceComparison = other.isReference == this->isReference || other.token == ID;
    bool argumentsComparison = true;
    
    /*if(other.argumentTypes.size() != this->argumentTypes.size())
    {
        return false;
    }
    else{
        argumentsComparison = std::equal(other.argumentTypes.begin(), other.argumentTypes.end(), this->argumentTypes.begin());
    }*/
    
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
        for(auto& type : symbol.argumentTypes){
            stream << type << ' ';
        }
    }
	return stream;
}


const int Symbol::getTypeSize(int type)
{
    switch(type){
        case INTEGER:
            return Symbol::intSize;
        case REAL:
            return Symbol::floatSize;
    }
    return Symbol::UNDEFINED;
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
    case ARRAY:
        return "array";
	default:
		return "unknown";
	}
}


ostream & operator << (ostream & stream, Symbol::GeneralType & type)
{
    stream << Symbol::tokenToString(type.id);
    if(type.startIdx != Symbol::UNDEFINED && type.endIdx != Symbol::UNDEFINED){
        stream << '[' << type.startIdx << ".." << type.endIdx << ']';
    }
    return stream;
}
