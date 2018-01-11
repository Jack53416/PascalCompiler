#pragma once

#include <iostream>
#include "parser.hpp"
#include "SymbolTableManager.h"
#include "Emitter.h"
#include "Symbol.h"
using namespace std;

struct logger{
    void operator()(const char* cString) const{ 
        cout << cString << endl;
    }
};
extern unsigned int lineNumber;
int yylex();



