#include "Emitter.h"

Emitter::Emitter(const char* filepath)
{
	this->file.open(filepath, ios::out);
	currentTarget = &file;
}

Emitter::~Emitter()
{
	file.close();
}

void Emitter::switchTarget(TargetType target)
{
	if (target == FILE)
		currentTarget = &file;
	else
		currentTarget = &buffer;
}

void Emitter::putBufferIntoFile()
{
	file << buffer.rdbuf();
    buffer.str(std::string());
}

string Emitter::formatLine(const string & label, const string & opcode, const string & args, const string & debugArgs) const
{
	stringstream output;
	if (label.size() > 0) {
		output << setw(Emitter::normalColWidth) << left << label + ":";
	}
	else {
		output << setw(Emitter::normalColWidth) << left << ' ';
	}

	output << setw(Emitter::normalColWidth) << left << opcode
	<< setw(1) << ' '
	<< setw(2 * Emitter::normalColWidth) << left << args
	<< setw(Emitter::debugSpacing) << left << '\t';
		
	if (debugArgs.size() > 0) {
		output << setw(Emitter::normalColWidth) << left << ';' + opcode
			<< setw(1) << ' '
			<< setw(2 * Emitter::normalColWidth) << left << debugArgs;
	}
	return output.str();
}

string Emitter::formatLine(const string & label) const
{
	return formatLine(label, "", "", "");
}

string Emitter::formatLine(const string & opcode, const string & args, const string & debugArgs) const
{
	return formatLine("", opcode, args, debugArgs);
}

void Emitter::emitError(const string & error, unsigned int lineNumber) const
{
	std::cerr << "\033[1;31mError in lnie: " << lineNumber << "\033[0m\t" << error << endl;
}

void Emitter::emitWarning(const string & warning, unsigned int lineNumber) const
{
	std::cerr << "\033[1;33mWarning in lnie: " << lineNumber << "\033[0m\t" << warning << endl;
}

Emitter & Emitter::operator<<(const string & value)
{
	*currentTarget << value << endl;
	return *this;
}
