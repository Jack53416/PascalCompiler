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
}

Emitter & Emitter::operator<<(const string & value)
{
	*currentTarget << value << endl;
	return *this;
}
