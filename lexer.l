%{
    #include <iostream>
    #include "global.hpp"
    using namespace std;
    
    emitter print;
	SymbolTableManager& symbolTable = SymbolTableManager::getInstance();
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
{integer}       { yylval = symbolTable.lookUpPush(NUM, yytext); NUM; }
{num}           { yylval = symbolTable.lookUpPush(NUM, yytext); return NUM; }

{sign}          { return SIGN; }
{assignop}      { return ASSIGNOP; }
{mulop}         { return MULOP; }
{relop}         { return RELOP; }

program         { return PROGRAM; }
var             { return VAR;  }
array           { return ARRAY; }
of              { return OF; }
integer         { return INTEGER; }
real            { return REAL; }
function        { return FUNCTION; }
procedure       { return PROCEDURE; }
begin           { return BEGIN_TOKEN; }
end             { return END; }

or              { return OR; }
not             { return NOT; }
if              { return IF; }
then            { return THEN; }
else            { return ELSE; }
do              { return DO; }
while           { return WHILE; }

{id}            { yylval = symbolTable.lookUpPush(ID, yytext); return ID;}

<<EOF>>         { return DONE; }
.               { return yytext[0];}

%%


