#ifndef GLOBAL_H
#define GLOBAL_H

#include <iostream>
#include "parser.hpp"
#include "SymbolTableManager.hpp"

using namespace std;

struct emitter{
    void operator()(const char* cString) const{ 
        cout << cString << endl;
    }
};
extern int yyparse();
int yylex();


#endif 
