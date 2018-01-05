#include <iostream>

#include "parser.hpp"

using namespace std;

int main (int argc, char* argv[])
{
    yyparse();
    return 0;
}
