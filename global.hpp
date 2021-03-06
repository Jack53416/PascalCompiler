#pragma once

#include <iostream>
#include "parser.hpp"
#include "SymbolTableManager.h"
#include "Emitter.h"
#include "Symbol.h"

using namespace std;

extern unsigned int lineNumber;
extern bool allowIdSymbols;
extern Emitter emitter;
extern FILE* yyin;
extern SymbolTableManager& symboltable;


/*main.cpp*/
int yylex();
void initSymbolTable();
void initInputOutput(int argc, char* argv[], FILE *inputFile);

/*lexer.l*/
int getOperationToken(const string & opSign);

/*Parser.y*/
void assignParameterType(int typeId);
string getOpCode(int opToken);
YYSTYPE cast(YYSTYPE varIdx, Symbol::GeneralType newType);
YYSTYPE checkTypes(YYSTYPE& var1,YYSTYPE& var2);
bool checkIfUndecalred(unsigned int argCount, ...);
void pushFunctionParams(Symbol &function, vector<YYSTYPE> &arguments);
void handleSubprogramCall(YYSTYPE programId, YYSTYPE& resultId, vector<YYSTYPE> &arguments, bool callRecursively);
void genCode(const string & opCode, const Symbol *result, bool resref, const Symbol* arg1, bool arg1ref,  const Symbol* arg2, bool arg2ref);
void yyerror(const string & s);
