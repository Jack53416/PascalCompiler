#include "Symbol.h"
#include <sstream>
#include <iomanip>

Symbol::Symbol()
	:token(UNDEFINED), type(), address(UNDEFINED), isReference(false), isLocal(false)
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

	if (token == NUM) {
		output << '#' << value;
		return output.str();
	}

	if (isReference)
		output << '*';
	if (isLocal) {
		output << "BP";
		if (address > 0) {
			output << '+';
		}
	}



	output << address;
	return output.str();
}

int Symbol::getSize() const
{
	if (type.id == REAL && !isReference)
		return floatSize;
	else if (type.id == INTEGER || isReference)
		return intSize;
	else if (type.id == ARRAY) {
			return (type.endIdx - type.startIdx + 1) * Symbol::getTypeSize(type.subtype);
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
	bool typeComparison = other.type == this->type || other.type.id == UNDEFINED;
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
	stream << setw(4) << left << Symbol::tokenToString(symbol.token)
		<< setw(8) << left << "\tvalue: " << setw(10) << left << symbol.value;
	if (symbol.type.id != Symbol::UNDEFINED) {
		stream  <<  "\ttype: " << setw(10) <<  left << symbol.type;
	}
	if (symbol.address != Symbol::UNDEFINED) {
		stream << setw(8) << "\taddress: " << setw(4) << symbol.address;
	}
	if (symbol.isReference != false) {
		stream << setw(11) << "\treference";
	}
	if (symbol.argumentTypes.size() > 0) {
		stream << setw(8) << "\targTypes: ";
		for (auto& type : symbol.argumentTypes) {
			stream << type << ' ';
		}
	}
	return stream;
}


const int Symbol::getTypeSize(int type)
{
	switch (type) {
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
    case Symbol::UNDEFINED:
        return "UNDEFINED";
	default:
		return "unknown";
	}
}

Symbol::GeneralType::GeneralType()
	: id(Symbol::UNDEFINED), subtype(Symbol::UNDEFINED), startIdx(Symbol::UNDEFINED), endIdx(Symbol::UNDEFINED)
{

}

Symbol::GeneralType::GeneralType(int typeId)
	:GeneralType()
{
	id = typeId;
}

bool Symbol::GeneralType::operator==(const GeneralType & other) const
{
	if (other.id == Symbol::UNDEFINED || this->id == Symbol::UNDEFINED)
		return false;

	if (other.id == this->id &&
		other.subtype == this->subtype &&
		other.startIdx == this->startIdx &&
		other.endIdx == this->endIdx) {
		return true;
	}
	return false;
}

bool Symbol::GeneralType::operator!=(const GeneralType & other) const
{
	if (other == *this)
		return false;
	return true;
}

ostream & operator << (ostream & stream, Symbol::GeneralType & type)
{
    stringstream output;
    
    if(type.id != ARRAY)
        output << Symbol::tokenToString(type.id);

    if(type.subtype != Symbol::UNDEFINED)
        output << Symbol::tokenToString(type.subtype);

    if (type.startIdx != Symbol::UNDEFINED && type.endIdx != Symbol::UNDEFINED) {
        output << '[' << type.startIdx << ".." << type.endIdx << ']';
    }
    stream << output.str();
    return stream;
}
