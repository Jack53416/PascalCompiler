#include <iostream>
#include "global.hpp"

using namespace std;
void initSymbolTable();

int main (int argc, char* argv[])
{
    initSymbolTable();
    yyparse();
    return 0;
}

void initSymbolTable()
{
    SymbolTableManager& symbolTable = SymbolTableManager::getInstance();
    symbolTable.push(PROCEDURE, "write");
    symbolTable.push(PROCEDURE, "read");
}
