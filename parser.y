%{
	#include "global.hpp"
	#include <iostream>
	#include <vector>
	using namespace std;
	
	SymbolTableManager& symboltable = SymbolTableManager::getInstance();
    
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
                            {emitter << emitter.getLabel(); indentifierListVect.clear();}
                            declarations
                            subprogram_declarations
                            compound_statement '.'
                            { cout << symboltable;}
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


type:                       standard_type {$$ = $1;}
                            | ARRAY '[' NUM ".." NUM ']' OF standard_type
                            ;

standard_type:              INTEGER {$$ = INTEGER;}
                            | REAL {$$ = REAL;}
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
                               /* if($2 == '+'){
                                    emitter << "add.i " + to_string(symboltable[$1].address) + ',' + to_string(symboltable[$3].address) + ',' + "$t0";
                                }*/
                            }
                            | simple_expression OR term
                            ;
                            
term:                       factor {$$ = $1;}
                            | term MULOP factor
                            ;
                        
factor:                     variable
                            | ID '(' expression_list ')'
                            | NUM {$$ = $1;}
                            | '(' expression ')'
                            | NOT factor
                            ;
                        
%%

void yyerror(const char* s){
    log("Error occured!");
}
	 

