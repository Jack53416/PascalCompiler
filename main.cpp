#include <iostream>
#include "global.hpp"

using namespace std;
const string defaultFileName = "output.asm";
Emitter emitter;

int main (int argc, char* argv[])
{
    FILE * inputFile = nullptr;
    
    try{
        initInputOutput(argc, argv, inputFile);
    }
    catch (const ios_base::failure & ex){
        cout << ex.what() << endl;
        if(inputFile){
            fclose(inputFile);
        }
        return 0;
    }
    
    initSymbolTable();
    yyparse();
    
    if(inputFile){
        fclose(inputFile);
    }
    
    return 0;
}


void initInputOutput(int argc, char* argv[], FILE *inputFile)
{
    emitter.openFile(defaultFileName);
    if (argc >= 2){
        inputFile = fopen(argv[1], "r");
        if (!inputFile){
            throw ios_base::failure("Error opening input file!");
        }
        yyin = inputFile;
    }
    
    if (argc >= 3) {
        emitter.openFile(argv[2]);
    }
}

void initSymbolTable()
{
    SymbolTableManager& symbolTable = SymbolTableManager::getInstance();
    symbolTable.push(PROCEDURE, "write");
    symbolTable.push(PROCEDURE, "read");
}
