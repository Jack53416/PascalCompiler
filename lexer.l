%{
    #include <iostream>
    #include "global.hpp"
    using namespace std;
    
    emitter print;
	
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
{num}           { return NUM; }

{sign}          { return SIGN; }
{assignop}      {print("assignop"); }
{mulop}         { return MULOP; }
{relop}         { return RELOP; }

program         {print("program"); }
var             {print("var"); }
array           {print("array"); }
of              {print("of"); }
integer         {print("integer"); }
real            {print("float"); }
function        {print("function"); }
procedure       {print("procedure"); }
begin           {print("begin"); }
end             {print("end");}

or              { return OR; }
not             { return NOT; }
if              {print("if"); }
then            {print("then"); }
else            {print("else"); }
do              {print("do"); }
while           {print("while"); }

{id}            {print("id");}

<<EOF>>         {return DONE;}
.               { return yytext[0];}

%%


