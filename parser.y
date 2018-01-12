%{
	#include "global.hpp"
	#include <iostream>
	#include <vector>
	#include <cstdarg>
	using namespace std;
	
	SymbolTableManager& symboltable = SymbolTableManager::getInstance();
    void genCode(const string& opCode, const Symbol& result, int argCount, ...);
    int cast(int varIdx, int newType);
    int checkTypes(int& var1, int& var2);
    
	void yyerror(const char* s);
	Emitter emitter("binary.asm");
	logger log;
	vector<int> indentifierListVect;
	vector<int> parameterListVect;

%}

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
                                symboltable.setGlobalScope();
                            }
                            ;

                        
subprogram_head:            FUNCTION ID 
                            {
                                Symbol symbol = symboltable[$2];
                                symboltable[$2].token = FUNCTION;
                                emitter<< symboltable[$2].value + ":";
                                 
                                symboltable.setLocalScope();
                                symbol.token = VAR;
                                symbol.isReference = true;
                                symboltable.assignFreeAddress(symbol, true);
                                symboltable.push(symbol);
                               
                                emitter.switchTarget(Emitter::TargetType::BUFFER);
                            } 
                            arguments ':' standard_type ';'
                            {
                                symboltable.setGlobalScope();
                                symboltable[$2].type = $5;
                                symboltable[$2].argumentTypes = parameterListVect; 
                                parameterListVect.clear();
                                symboltable.setLocalScope();
                                symboltable[0].type = $5;
                            }
                            | PROCEDURE ID 
                            {
                                symboltable[$2].token = PROCEDURE;
                                symboltable.setLocalScope();
                            } 
                            arguments ';'
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
                                if(symboltable[$1].type == INTEGER && symboltable[$3].type == REAL){
                                    yyerror("Assigning real type to integer!");
                                }
                                
                                if(symboltable[$3].type != symboltable[$1].type){
                                    $3 = cast($3, symboltable[$1].type);
                                }
                                genCode("mov",symboltable[$1], 1, symboltable[$3]);
                            }
                            | procedure_statement
                            | compound_statement
                            | IF expression THEN statement ELSE statement
                            | WHILE expression DO statement
                            ;


variable:                   ID 
                            | ID '[' expression ']'
                            ;


procedure_statement:        ID
                            | ID '(' expression_list ')'
                            {
                                if(symboltable[$1].value.compare("write") == 0){
                                    
                                    for(int& param : parameterListVect){
                                        genCode("write", symboltable[param], 0);
                                    }
                                }
                                if(symboltable[$1].value.compare("read") == 0){
                                    for(int& param : parameterListVect){
                                        genCode("read", symboltable[param], 0);
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
                            | NUM {$$ = $1;}
                            | '(' expression ')'
                            | NOT factor
                            ;
                        
%%

void yyerror(const char* s){

    cout<< "\033[1;31mError in lnie: " << lineNumber << "\033[0m\t" << s<<endl;
}

#include <sstream>


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
        output << convOpCode << ' ' << symboltable[varIdx].getCodeformat() << ',' << symboltable[tmpIdx].getCodeformat();
        emitter << output.str();
        return tmpIdx;
    }
    
    return varIdx;
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
		output << va_arg(symbols, Symbol).getCodeformat() << ',';
	}
	output << result.getCodeformat();
	
	
	emitter << output.str();

}

