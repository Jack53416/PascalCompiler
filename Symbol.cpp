#include "Symbol.h"


Symbol::Symbol()
{
}


Symbol::Symbol(int tokenCode, string tokenVal, int tokenType)
	: token(tokenCode), value(tokenVal), type(tokenType), address(UNDEFINED)
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

bool Symbol::operator==(const Symbol & other) const
{
	bool tokenComparison = other.token == this->token || other.token == ID;
	bool valueComparison = other.value.compare(this->value) == 0;
	bool typeComparison = other.type == this->type || other.type == UNDEFINED;
	if (tokenComparison && valueComparison && typeComparison) {
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
		return "number";
	case INTEGER:
		return "integer";
	case REAL:
		return "real";
	case FUNCTION:
		return "function";
	case PROCEDURE:
		return "procedure";
	default:
		return "unknown";
	}
}
