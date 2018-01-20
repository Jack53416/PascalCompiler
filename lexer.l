%{
    #include <iostream>
    #include "global.hpp"
    
	SymbolTableManager& symboltable = SymbolTableManager::getInstance();
	
	bool allowIdSymbols = true;
	unsigned int lineNumber = 1;
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
mulop       [*\/]|and|mod|div
relop       [<>]|<=|>=|=
assignop    :=
%%

{delimiter}     {}
\n              {lineNumber++;}
{integer}       { 
                    yylval = symboltable.lookUpPush(NUM, yytext, INTEGER);
                    return NUM; 
                }
{num}           { 
                    yylval = symboltable.lookUpPush(NUM, yytext, REAL); 
                    return NUM; 
                }

{sign}          {
                    yylval = getOperationToken(yytext);
                    return SIGN; 
                }
{assignop}      { return ASSIGNOP; }
{mulop}         {
                    yylval = getOperationToken(yytext);
                    return MULOP; 
                }
{relop}         {
                    yylval = getOperationToken(yytext);
                    return RELOP; 
                }

program         { return PROGRAM; }
var             { return VAR;  }
array           { return ARRAY; }
of              { return OF; }
integer         {
                    yylval = INTEGER;
                    return INTEGER; 
                }
real            {
                    yylval = REAL;
                    return REAL; 
                }
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
for             { return FOR; }
to              { return TO; }

{id}            { 
                    if(allowIdSymbols)
                        yylval = symboltable.lookUpPush(ID, yytext);
                    else
                        yylval = symboltable.lookUp(yytext, true);
                    return ID;
                }

<<EOF>>         { return DONE; }
.               { return yytext[0];}

%%
int getOperationToken(const string & opSign)
{
    if( opSign == ">=") return GREATER_EQUAL;
    if( opSign == "<=") return LESS_EQUAL;
    if( opSign == "mod") return MOD;
    if( opSign == "div") return DIV;
    if( opSign == "and") return AND;
    return opSign[0];
}

