#ifndef GLOBAL_H
#define GLOBAL_H

#include <iostream>

using namespace std;

struct emitter{
    void operator()(const char* cString) const{ 
        cout << cString << endl;
    }
};

int yylex();

#endif 
