#ifndef GLOBAL_H
#define GLOBAL_H

#include <iostream>
#include "parser.hpp"
#include "SymbolTableManager.h"
#include "Emitter.h"

using namespace std;

struct logger{
    void operator()(const char* cString) const{ 
        cout << cString << endl;
    }
};
extern int yyparse();
int yylex();


#endif 
