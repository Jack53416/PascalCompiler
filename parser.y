%{
	#include "global.hpp"
	#include <iostream>
	#include <vector>
	using namespace std;
	
	SymbolTableManager& symboltable = SymbolTableManager::getInstance();
    void genCode(const string& opCode, SymbolTableManager::Symbol& v1, SymbolTableManager::Symbol& v2, SymbolTableManager::Symbol& result);
    void genCode(const string& opCode, SymbolTableManager::Symbol& v1, SymbolTableManager::Symbol& result);
    int cast(int varIdx, int newType);
    int checkTypes(int& var1, int& var2);
    
	void yyerror(const char* s);
	Emitter emitter("binary.asm");
	logger log;
	vector<int> indentifierListVect;

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
                                emitter << "\tjump.i #lab0" << emitter.getLabel() + ":"; 
                                indentifierListVect.clear();
                            }
                            declarations
                            subprogram_declarations
                            compound_statement '.'
                            { cout << symboltable; emitter <<"\twrite.r 8" << "\texit";}
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
                                    symboltable.assignFreeAddress(symboltable[id]);
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
                            ;

                        
subprogram_head:            FUNCTION ID arguments ':' standard_type ';'
                            | PROCEDURE ID arguments ';'
                            ;


arguments:                  '(' parameter_list ')'
                            |
                            ;


parameter_list:              identifier_list ':' type
                            | parameter_list ';' identifier_list ':' type
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
                                
                                if(symboltable[$3].token == VAR && symboltable[$3].type != symboltable[$1].type){
                                    $3 = cast($3, symboltable[$1].type);
                                }
                                genCode("mov",symboltable[$3], symboltable[$1]);
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
                            ;

expression_list:            expression
                            | expression_list ',' expression
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
                                    genCode("add", symboltable[$1], symboltable[$3], symboltable[$$]);
                                }
                                else{
                                    genCode("sub", symboltable[$1], symboltable[$3], symboltable[$$]);
                                }
                            }
                            | simple_expression OR term     
                            ;
                            
term:                       factor
                            | term MULOP factor
                            {
                                $$ = checkTypes($1, $3);
                                if($2 == '*'){
                                    genCode("mul", symboltable[$1], symboltable[$3], symboltable[$$]);
                                }
                                else{
                                    genCode("div", symboltable[$1], symboltable[$3], symboltable[$$]);
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
    log(s);
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

    if(symboltable[varIdx].token == VAR){
        tmpIdx = symboltable.pushTempVar(newType);
        output << convOpCode << ' ' << symboltable[varIdx].address << ',' << symboltable[tmpIdx].address;
        emitter << output.str();
        return tmpIdx;
    }
    
    return varIdx;
}

void genCode(const string& opCode, SymbolTableManager::Symbol& v1, SymbolTableManager::Symbol& result){
    stringstream output;
    output << '\t' << opCode << '.';
    
    if(result.type == REAL)
        output << 'r';
    else
        output << 'i';
    
    output << ' ' << v1.getCodeformat() << ',' << result.getCodeformat();
    emitter << output.str();
}

void genCode(const string& opCode, SymbolTableManager::Symbol& v1, SymbolTableManager::Symbol& v2, SymbolTableManager::Symbol& result){
    
    stringstream output;
    output << '\t' << opCode << '.';
    
    if(result.type == REAL)
        output << 'r';
    else
        output << 'i';
    
    
    output << ' ' << v1.getCodeformat() << ',' << v2.getCodeformat() << ',' << result.getCodeformat();
    emitter << output.str();
}
	 

