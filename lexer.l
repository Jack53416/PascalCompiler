%{
    #include <iostream>
    #include "global.hpp"
    using namespace std;
    
	SymbolTableManager& symbolTable = SymbolTableManager::getInstance();
	bool allowIdSymbols = true;
	
	unsigned int lineNumber = 0;
	unsigned int charNumber = 0;
%}
%option noyywrap

delimiter	[ \t]+
letter      [a-zA-Z]
digit       [0-9]

id  		({letter}|_)({letter}|{digit}|_)*
integer     {digit}+
fraction    \.{digit}+
exponent    [eE][+-]?{digit}+
num         {integer}{fraction}?{exponent}?

sign        [+\-]
mulop       [*\/]
relop       [<>]|<=|>=|==
assignop    :=



%%

{delimiter}     {charNumber++; }
\n              {lineNumber++; charNumber = 0;}
{integer}       { 
                    yylval = symbolTable.lookUpPush(NUM, yytext, INTEGER);
                    return NUM; 
                }
{num}           { 
                    yylval = symbolTable.lookUpPush(NUM, yytext, REAL); 
                    return NUM; 
                }

{sign}          {
                    yylval = yytext[0];
                    return SIGN; 
                }
{assignop}      { return ASSIGNOP; }
{mulop}         {
                    yylval = yytext[0];
                    return MULOP; 
                }
{relop}         {
                    yylval = yytext[0];
                    return RELOP; 
                }

program         { return PROGRAM; }
var             { return VAR;  }
array           { return ARRAY; }
of              { return OF; }
integer         { return INTEGER; }
real            { return REAL; }
function        { return FUNCTION; }
procedure       { return PROCEDURE; }
begin           { allowIdSymbols = false; return BEGIN_TOKEN; }
end             { return END; }

or              { return OR; }
not             { return NOT; }
if              { return IF; }
then            { return THEN; }
else            { return ELSE; }
do              { return DO; }
while           { return WHILE; }

{id}            { 
                    if(allowIdSymbols)
                        yylval = symbolTable.lookUpPush(ID, yytext);
                    return ID;
                }

<<EOF>>         { return DONE; }
.               { return yytext[0];}

%%


