%{
	#include "global.hpp"
	#include <iostream>
	#include <vector>
	#include <algorithm>
	#include <cstdarg>
	using namespace std;
	
	SymbolTableManager& symboltable = SymbolTableManager::getInstance();
    void genCode(const string& opCode, const Symbol& result, int argCount, ...);
    int cast(int varIdx, int newType);
    int checkTypes(int& var1, int& var2);
    bool checkIfUndecalred(int argCount, ...);
    
    void handleSubprogramCall(int programId, int& resultId, vector<int> &arguments);
    void pushFunctionParams(int functionId, vector<int> &arguments);
    
	void yyerror(const string & s);
	Emitter emitter("binary.asm");
	vector<int> indentifierListVect;
	vector<int> parameterListVect;

%}
%define api.value.type {int}
%token PROGRAM
%token ID
%token VAR
%token ARRAY
%token NUM
%token OF
%token INTEGER
%token REAL
%token FUNCTION
%token PROCEDURE
%token BEGIN_TOKEN
%token END
%token ASSIGNOP
%token IF
%token THEN
%token ELSE
%token WHILE
%token DO
%token RELOP
%token SIGN
%token OR
%token MULOP
%token NOT
%token DONE 0

%%

program:                    PROGRAM ID '(' identifier_list ')' ';'
                            {
                                emitter << "\tjump.i #lab0";
                                indentifierListVect.clear();
                            }
                            declarations
                            subprogram_declarations
                            {
                              emitter << emitter.getLabel() + ":"; 
                            }
                            compound_statement '.'
                            { cout << symboltable; emitter <<"\texit";}
                            ;


identifier_list:            ID
                            {
                                indentifierListVect.push_back($1);
                            }
                            | identifier_list ',' ID
                            {
                                indentifierListVect.push_back($3);
                            }
                            ;


declarations:               declarations VAR identifier_list ':' type ';'
                            {
                                for(int id : indentifierListVect){
                                    symboltable[id].token = VAR;
                                    symboltable[id].type = $5;
                                    symboltable.assignFreeAddress(symboltable[id], false);
                                }
                                indentifierListVect.clear();
                            }
                            |
                            ;


type:                       standard_type
                            | ARRAY '[' NUM ".." NUM ']' OF standard_type
                            ;

standard_type:              INTEGER
                            | REAL 
                            ;

subprogram_declarations:    subprogram_declarations subprogram_declaration ';'
                            |
                            ;

subprogram_declaration:     subprogram_head declarations compound_statement
                            {
                    
                                emitter << "\tleave" << "\treturn";
                                emitter.switchTarget(Emitter::TargetType::FILE);
                                emitter << "\tenter.i #" + to_string(symboltable.getStackSize());
                                emitter.putBufferIntoFile();
                                allowIdSymbols = true;
                                
                                cout << symboltable;
                                symboltable.clearScope();
                                symboltable.setGlobalScope();
                            }
                            ;

                        
subprogram_head:            FUNCTION ID 
                            {
                                if(checkIfUndecalred(1, $2)){
                                      YYERROR;
                                }
                                
                                Symbol funReturnValue = symboltable[$2];
                                Symbol& fun = symboltable[$2];
                                
                                fun.token = FUNCTION;
                                emitter<< fun.value + ":";
                                 
                                symboltable.setLocalScope();
                                
                                funReturnValue.token = VAR;
                                funReturnValue.isReference = true;
                                symboltable.assignFreeAddress(funReturnValue, true);
                                symboltable.push(funReturnValue);
                               
                                emitter.switchTarget(Emitter::TargetType::BUFFER);
                            } 
                            arguments ':' standard_type ';'
                            {
                                symboltable.setGlobalScope();
        
                                symboltable[$2].type = $7;
                                symboltable[$2].argumentTypes = parameterListVect; 
                                parameterListVect.clear();
                                symboltable.setLocalScope();
                                symboltable[0].type = $7;
                            }
                            | PROCEDURE ID 
                            {
                                symboltable[$2].token = PROCEDURE;
                                emitter<< symboltable[$2].value + ":";
                                symboltable.setLocalScope();
                                emitter.switchTarget(Emitter::TargetType::BUFFER);
                            } 
                            arguments ';'
                            {
                                symboltable.setGlobalScope();
                                
                                symboltable[$2].argumentTypes = parameterListVect;
                                parameterListVect.clear();
                                
                                symboltable.setLocalScope();
                            }
                            ;


arguments:                  '(' parameter_list ')'
                            |
                            ;


parameter_list:              identifier_list ':' type
                            {
                                for(int id : indentifierListVect){
                                    symboltable[id].token = VAR;
                                    symboltable[id].isReference = true;
                                    symboltable[id].type = $3;
                                    symboltable.assignFreeAddress(symboltable[id], true);
                                    
                                    parameterListVect.push_back($3);
                                }
                                indentifierListVect.clear();
                            }
                            | parameter_list ';' identifier_list ':' type
                            {
                                for(int id : indentifierListVect){
                                    symboltable[id].token = VAR;
                                    symboltable[id].isReference = true;
                                    symboltable[id].type = $5;
                                    symboltable.assignFreeAddress(symboltable[id], true);
                                    
                                    parameterListVect.push_back($5);
                                }
                                indentifierListVect.clear();
                            }
                            ;

compound_statement:         BEGIN_TOKEN optional_statements END

                            ;

optional_statements:        statement_list
                            |
                            ;


statement_list:             statement
                            | statement_list ';' statement
                            ;


statement:                  variable ASSIGNOP expression
                            {
                                
                               try{
                                    if(symboltable[$1].type == INTEGER && symboltable[$3].type == REAL){
                                        yyerror("Assigning real type to integer!");
                                    }
                                    
                                    if(symboltable[$3].type != symboltable[$1].type){
                                        
                                        $3 = cast($3, symboltable[$1].type);
                                    }
                                    genCode("mov",symboltable[$1], 1, symboltable[$3]);
                                }
                                catch(const std::out_of_range &ex){
                                    yyerror("Undeclared Identifier");
                                    YYERROR;
                                }
                            }
                            | procedure_statement
                            | compound_statement
                            | IF expression THEN statement ELSE statement
                            | WHILE expression DO statement
                            ;


variable:                   ID 
                            {
                                try{
                                    handleSubprogramCall($1, $$, parameterListVect);
                                }
                                catch(const std::invalid_argument &ex){
                                    yyerror(ex.what());
                                    YYERROR;
                                }
                                catch(const std::out_of_range &ex){
                                    yyerror("Undeclared Identifier");
                                    YYERROR;
                                }
                                if(symboltable[$1].token == PROCEDURE){
                                    yyerror("Procedure can't return value!");
                                    YYERROR;
                                }
                            }
                            | ID '[' expression ']'
                            ;


procedure_statement:        ID
                            {
                                try{
                                    handleSubprogramCall($1, $$, parameterListVect);
                                }
                                catch(const std::invalid_argument &ex){
                                    yyerror(ex.what());
                                    YYERROR;
                                }
                                catch(const std::out_of_range &ex){
                                    yyerror("Undeclared Identifier");
                                    YYERROR;
                                }
                                
                            }
                            | ID '(' expression_list ')'
                            {
                                if(checkIfUndecalred(1, $1)){
                                      YYERROR;
                                }
                                
                                if(symboltable[$1].value.compare("write") == 0 ){
                                    
                                    for(int& param : parameterListVect){
                                        genCode("write", symboltable[param], 0);
                                    }
                                   
                                }
                                else if(symboltable[$1].value.compare("read") == 0){
                                    for(int& param : parameterListVect){
                                        genCode("read", symboltable[param], 0);
                                    }
                                }
                                
                                else {
                                    try{
                                        handleSubprogramCall($1, $$, parameterListVect);
                                    }
                                    catch(const std::invalid_argument &ex){
                                        yyerror(ex.what());
                                        YYERROR;
                                    }
                                    catch(const std::out_of_range &ex){
                                        yyerror("Undeclared Identifier");
                                        YYERROR;
                                    }
                                }
                                parameterListVect.clear();
                            }
                            ;

expression_list:            expression
                            {
                                parameterListVect.push_back($1);
                            }
                            | expression_list ',' expression
                            {
                                parameterListVect.push_back($3);
                            }
                            ;

expression:                 simple_expression
                            | simple_expression RELOP simple_expression
                            ;

simple_expression:          term 
                            | SIGN term 
                            | simple_expression SIGN term 
                            {
                                if(checkIfUndecalred(2, $1, $3)){
                                      YYERROR;
                                }
                                $$ = checkTypes($1, $3);
                                if($2 == '+'){
                                    genCode("add",symboltable[$$], 2 , symboltable[$1], symboltable[$3]);
                                }
                                else{
                                    genCode("sub",symboltable[$$], 2 , symboltable[$1], symboltable[$3]);
                                }
                            }
                            | simple_expression OR term     
                            ;
                            
term:                       factor
                            | term MULOP factor
                            {
                                if(checkIfUndecalred(2, $1, $3)){
                                      YYERROR;
                                }
                                $$ = checkTypes($1, $3);
                                if($2 == '*'){
                                    genCode("mul",symboltable[$$], 2 , symboltable[$1], symboltable[$3]);
                                }
                                else{
                                    genCode("div",symboltable[$$], 2 , symboltable[$1], symboltable[$3]);
                                }
                                
                            }
                            ;
                        
factor:                     variable
                            | ID '(' expression_list ')'
                            
                            {
                                try{
                                    handleSubprogramCall($1, $$, parameterListVect);
                                }
                                catch(const std::invalid_argument &ex){
                                    yyerror(ex.what());
                                    YYERROR;
                                }
                                catch(const std::out_of_range &ex){
                                    yyerror("Undeclared Identifier");
                                    YYERROR;
                                }
                                parameterListVect.clear();
                            }
                            | NUM
                            | '(' expression ')'
                            | NOT factor
                            ;
                        
%%

void yyerror(const string & s){
    cout << symboltable;
    std::cerr<< "\033[1;31mError in lnie: " << lineNumber << "\033[0m\t" << s<<endl;
}

#include <sstream>


void handleSubprogramCall(int programId, int& resultId, vector<int> &arguments){
    Symbol& subprogram = symboltable[programId];
    int programResultId = -1;
    
    if(!(subprogram.token == FUNCTION || subprogram.token == PROCEDURE))
        return;
        
    if(subprogram.argumentTypes.size() != arguments.size()){
        throw std::invalid_argument("Wrong argument count, required " 
                + to_string(subprogram.argumentTypes.size()) + ", got "
                + to_string(arguments.size()));
    }

    if(subprogram.token == FUNCTION){
        programResultId = symboltable.pushTempVar(subprogram.type);
        resultId = programResultId;
    }

    pushFunctionParams(programId, arguments);
    
    if(subprogram.token == FUNCTION)
        emitter << "\tpush.i #" + to_string(symboltable[programResultId].address);
    
    emitter << "\tcall.i #" + subprogram.value;
    
    if(subprogram.token == FUNCTION)
        emitter << "\tincsp.i #" + to_string((arguments.size() + 1) * Symbol::intSize);
    else if(arguments.size() > 0)
        emitter<< "\tincsp.i #" + to_string((arguments.size() * Symbol::intSize));
}

void pushFunctionParams(int functionId, vector<int> &arguments){
    Symbol& function = symboltable[functionId];
    int argumentIdx = 0;
    int parameterIdx = function.argumentTypes.size() - 1;
    
    std::reverse(arguments.begin(), arguments.end());
    
    for(int param: arguments){
        argumentIdx = param;
        
        if(symboltable[param].token == NUM){
            argumentIdx = symboltable.pushTempVar(symboltable[param].type);
            genCode("mov", symboltable[argumentIdx], 1, symboltable[param]);
        }
        
        if(symboltable[argumentIdx].type != function.argumentTypes.at(parameterIdx)){
            argumentIdx = cast(argumentIdx, function.argumentTypes.at(parameterIdx));
        }
        
        emitter << "\tpush.i #" + to_string(symboltable[argumentIdx].address);
        parameterIdx--;
    }
    
}

int checkTypes(int& var1, int& var2){
    if(symboltable[var1].type != symboltable[var2].type){
        if(symboltable[var1].type == INTEGER)
            var1 =  cast(var1, REAL);
        
        else
            var2 = cast(var2, REAL);
    }
    return symboltable.pushTempVar(symboltable[var1].type);
}


int cast(int varIdx, int newType){
    int tmpIdx = 0;
    string convOpCode;
    stringstream output;
    
    if(newType == INTEGER)
        convOpCode = "\trealtoint.i";
    else
        convOpCode = "\tinttoreal.i";


    if(symboltable[varIdx].token == VAR || (symboltable[varIdx].token == NUM && newType == INTEGER)){
   
        tmpIdx = symboltable.pushTempVar(newType);
        output << convOpCode << ' ' << symboltable[varIdx].getCodeformat(symboltable.isInGlobalScope()) << ',' << symboltable[tmpIdx].getCodeformat(symboltable.isInGlobalScope());
        emitter << output.str();
        if(varIdx == 9){cout << symboltable[varIdx] <<endl << convOpCode << endl << tmpIdx << endl;}
        return tmpIdx;
    }
    
    return varIdx;
}

bool checkIfUndecalred(int argCount, ...){
    va_list ids;
    va_start(ids, argCount);
    int idx = 0;
    try{
        for(int i = 0; i < argCount; i++){
            idx = va_arg(ids, int);
            symboltable[idx];
        }
    }
    catch (const std::out_of_range& ex){
        yyerror("Undeclared Identifier!");
        return true;
    }
    return false;
}

void genCode(const string& opCode, const Symbol& result, int argCount, ...) {
	va_list symbols;
	va_start(symbols, argCount);
	stringstream output;
	output << '\t' << opCode << '.';

	if (result.type == REAL)
		output << 'r';
	else
		output << 'i';

	output << ' ';

	for (int i = 0; i < argCount; i++) {
		output << va_arg(symbols, Symbol).getCodeformat(symboltable.isInGlobalScope()) << ',';
	}
	output << result.getCodeformat(symboltable.isInGlobalScope());
	
	
	emitter << output.str();

}

