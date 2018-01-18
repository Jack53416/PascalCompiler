%{
    #include "global.hpp"
    #include <iostream>
    #include <vector>
    #include <algorithm>
    #include <cstdarg>
    using namespace std;

    SymbolTableManager& symboltable = SymbolTableManager::getInstance();

    
    void genCode(const string & opCode, const Symbol *result, bool resref, const Symbol* arg1, bool arg1ref,  const Symbol* arg2, bool arg2ref);
    string getOpCode(int opToken);
    
    YYSTYPE cast(YYSTYPE varIdx, Symbol::GeneralType newType);
    YYSTYPE checkTypes(YYSTYPE& var1,YYSTYPE& var2);
    bool checkIfUndecalred(unsigned int argCount, ...);
    void handleSubprogramCall(YYSTYPE programId, YYSTYPE& resultId, vector<YYSTYPE> &arguments, bool callRecursively);
    void pushFunctionParams(Symbol &function, vector<YYSTYPE> &arguments);

    void yyerror(const string & s);
    Emitter emitter("binary.asm");
    
    vector<YYSTYPE> indentifierListVect;
    vector<YYSTYPE> parameterListVect;
    
    vector <Symbol::GeneralType> parameterTypesVect;
    Symbol::GeneralType arrayHelper;
    Symbol::GeneralType typeHelper;
    Symbol labelHelper(NUM, "lab", LABEL);
%}
%define api.value.type {long unsigned int}
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

%token LABEL
//Operation codes
%token DIV
%token MOD
%token GREATER_EQUAL
%token LESS_EQUAL
%token AND
%%

program:                    PROGRAM ID '(' identifier_list ')' ';'
                            {
                                emitter << "\tjump.i #" + emitter.getLabel();
                                indentifierListVect.clear();
                            }
                            declarations
                            subprogram_declarations
                            {
                              emitter <<"lab0:"; 
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
                                for(auto id : indentifierListVect){
                                    symboltable[id].token = VAR;
                                    symboltable[id].type.id = $5;
                                    //HERER!!!!
                                    if($5 == ARRAY){
                                        symboltable[id].type = arrayHelper;
                                    }
                                    symboltable.assignFreeAddress(symboltable[id], false);
                                }
                                parameterTypesVect.clear();
                                indentifierListVect.clear();
                                
                            }
                            |
                            ;


type:                       standard_type
                            | ARRAY '[' NUM '.''.' NUM ']' OF standard_type
                            {
                                if( symboltable[$3].type.id != INTEGER || symboltable[$6].type.id != INTEGER){
                                    yyerror("Invalid array definition, non integer range!");
                                    YYERROR;
                                }
                                arrayHelper.id = ARRAY;
                                arrayHelper.startIdx = std::stoi(symboltable[$3].value);
                                arrayHelper.endIdx = std::stoi(symboltable[$6].value);
                                
                                if( arrayHelper.startIdx >= arrayHelper.endIdx){
                                 yyerror("Invalid array definiton, invalid range!");
                                 YYERROR;
                                }
                                arrayHelper.subtype = $9;
                                $$ = ARRAY;
                            }
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
                        
                                cout << symboltable.clearScope();
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
                                symboltable.setScopeName(funReturnValue.value);
                                funReturnValue.token = VAR;
                                funReturnValue.isReference = true;
                                symboltable.assignFreeAddress(funReturnValue, true);
                                symboltable.push(funReturnValue);
                               
                                emitter.switchTarget(Emitter::TargetType::BUFFER);
                            } 
                            arguments ':' standard_type ';'
                            {
                                symboltable.setGlobalScope();
                                string funName = symboltable[$2].value;
                                
                                symboltable[$2].type.id = $7;
                                symboltable[$2].argumentTypes = parameterTypesVect;
                                parameterTypesVect.clear();
                                symboltable.setLocalScope();
                                symboltable[symboltable.lookUp(funName)].type.id = $7;
                            }
                            | PROCEDURE ID 
                            {
                                symboltable[$2].token = PROCEDURE;
                                emitter<< symboltable[$2].value + ":";
                                symboltable.setLocalScope();
                                symboltable.setScopeName(symboltable[$2].value);
                                emitter.switchTarget(Emitter::TargetType::BUFFER);
                            } 
                            arguments ';'
                            {
                                symboltable.setGlobalScope();
                                
                                symboltable[$2].argumentTypes = parameterTypesVect;
                                parameterTypesVect.clear();
                                
                                symboltable.setLocalScope();
                            }
                            ;


arguments:                  '(' parameter_list ')'
                            |
                            ;


parameter_list:              identifier_list ':' type
                            {
                                for(auto id : indentifierListVect){
                                    symboltable[id].token = VAR;
                                    symboltable[id].isReference = true;
                                    symboltable[id].type.id = $3;
                                    symboltable.assignFreeAddress(symboltable[id], true);
                                    
                                    typeHelper.id = $3;
                                    
                                    if($3 == ARRAY){
                                        symboltable[id].type = arrayHelper;
                                        parameterTypesVect.push_back(arrayHelper);
                                    }
                                    else{
                                       
                                        parameterTypesVect.push_back(typeHelper);
                                    }
                                }
                                indentifierListVect.clear();
                            }
                            | parameter_list ';' identifier_list ':' type
                            {
                                for(auto id : indentifierListVect){
                                    symboltable[id].token = VAR;
                                    symboltable[id].isReference = true;
                                    symboltable[id].type.id = $5;
                                    symboltable.assignFreeAddress(symboltable[id], true);
                                    
                                    typeHelper.id = $5;
                                    
                                    if($5 == ARRAY){
                                        symboltable[id].type = arrayHelper;
                                        parameterTypesVect.push_back(arrayHelper);
                                    }
                                    else{
                                        parameterTypesVect.push_back(typeHelper);
                                    }
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
                                    if(symboltable[$1].type.id == INTEGER && symboltable[$3].type.id == REAL){
                                        yyerror("Assigning real type to integer!");
                                    }
                                    
                                    if(symboltable[$3].type != symboltable[$1].type){
                                        
                                        $3 = cast($3, symboltable[$1].type);
                                    }
                                    genCode("mov",&symboltable[$1], false, &symboltable[$3], false, nullptr, false);
                                }
                                catch(const std::out_of_range &ex){
                                    yyerror("Undeclared Identifier");
                                    YYERROR;
                                }
                            }
                            | procedure_statement
                            | compound_statement
                            | IF expression 
                            {
                                labelHelper.value = emitter.getLabel();
                                YYSTYPE failValIdx = symboltable.lookUpPush(NUM, "0", INTEGER);
                                genCode("je", &labelHelper, false, &symboltable[$2], false, &symboltable[failValIdx], false);
                            }
                            THEN statement
                            {
                                Symbol labelSuccess = labelHelper;
                                labelHelper.value = emitter.getLabel();
                                genCode("jump", &labelHelper, false, nullptr, false, nullptr, false);
                                emitter << labelSuccess.value + ":";
                            }
                            ELSE statement
                            {
                                emitter << labelHelper.value + ":";
                            }
                            | WHILE
                            {
                                emitter.getLabel();
                                $$ = emitter.getLabel.labelNumber; //stop label
                                emitter << emitter.getLabel() + ":";
                                $1 = emitter.getLabel.labelNumber; //start label
                            }
                            expression DO
                            {
                                YYSTYPE failValIdx = symboltable.lookUpPush(NUM, "0", INTEGER);
                                labelHelper.value = emitter.getLabel($2);
                                genCode("je", &labelHelper, false, &symboltable[$3], false, &symboltable[failValIdx], false );
                            }
                            statement
                            {
                                labelHelper.value = emitter.getLabel($1);
                                genCode("jump", &labelHelper, false, nullptr, false, nullptr, false);
                                emitter << emitter.getLabel($2) + ":";
                            }
                            ;


variable:                   ID 
                            {
                                try{
                                    handleSubprogramCall($1, $$, parameterListVect, false);
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
                            
                            {
                                Symbol::GeneralType tempType;
                                tempType.id = INTEGER;
                                
                                if(symboltable[$1].type.id != ARRAY){
                                    yyerror("Expected array, got " + Symbol::tokenToString(symboltable[$1].type.id));
                                    YYERROR;
                                }
                                
                                const int elementSize = Symbol::getTypeSize(symboltable[$1].type.subtype);
                                YYSTYPE tmpVar = symboltable.pushTempVar(tempType);
                                $$ = symboltable.pushTempVar(symboltable[$1].type);
                                symboltable[$$].isReference = true;
                                
                                Symbol startIdx(NUM, to_string(symboltable[$1].type.startIdx), INTEGER);
                                Symbol elSize(NUM, to_string(elementSize), INTEGER);
                                
                    
                                genCode("sub", &symboltable[tmpVar], false, &symboltable[$3], false,  &startIdx, false);
                                genCode("mul", &symboltable[tmpVar], false,  &symboltable[tmpVar], false, &elSize, false);
                                genCode("add", &symboltable[$$], true, &symboltable[$1], true, &symboltable[tmpVar], false);
                                
                            }
                            ;


procedure_statement:        ID
                            {
                                try{
                                    handleSubprogramCall($1, $$, parameterListVect, false);
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
                                    
                                    for(auto& param : parameterListVect){
                                        genCode("write", &symboltable[param], false,  nullptr, false, nullptr, false);
                                    }
                                   
                                }
                                else if(symboltable[$1].value.compare("read") == 0){
                                    for(auto& param : parameterListVect){
                                        genCode("read", &symboltable[param], false, nullptr, false, nullptr, false);
                                    }
                                }
                                
                                else {
                                    try{
                                        if( symboltable[$1].value.compare(symboltable.getScopeName()) == 0 )
                                            handleSubprogramCall($1, $$, parameterListVect, true);
                                        else
                                            handleSubprogramCall($1, $$, parameterListVect, false);
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
                            
                            {
                                Symbol labelSuccess(NUM, emitter.getLabel(), LABEL);
                                Symbol labelDone(NUM, emitter.getLabel(), LABEL);
                                
                                YYSTYPE failValueIdx = symboltable.lookUpPush(NUM, "0", INTEGER);
                                YYSTYPE passValueIdx = symboltable.lookUpPush(NUM, "1", INTEGER);
                                
                                Symbol::GeneralType tmpType;
                                tmpType.id = INTEGER;
                                YYSTYPE tmpIdx = symboltable.pushTempVar(tmpType);
                        
                                genCode(getOpCode($2), &labelSuccess, false, &symboltable[$1], false, &symboltable[$3], false );
                                genCode("mov", &symboltable[tmpIdx], false, &symboltable[failValueIdx], false, nullptr, false );
                                genCode("jump", &labelDone, false, nullptr, false, nullptr, false);
                                emitter << labelSuccess.value + ":";
                                genCode("mov", &symboltable[tmpIdx], false, &symboltable[passValueIdx], false, nullptr, false);
                                emitter << labelDone.value + ":";
                                $$ = tmpIdx;
                            }
                            ;

simple_expression:          term 
                            | SIGN term 
                            {
                                Symbol zeroVal(NUM, "0", symboltable[$2].type.id);
                                YYSTYPE tmpIdx = 0;
                                if( $1 == '-'  && symboltable[$2].token == VAR){
                                    genCode("sub", &symboltable[$2], false, &zeroVal, false, &symboltable[$2], false);
                                }
                                else if ($1 == '-' && symboltable[$2].token == NUM){
                                    tmpIdx = symboltable.pushTempVar(symboltable[$2].type);
                                    genCode("sub", &symboltable[tmpIdx], false, &zeroVal, false, &symboltable[$2], false);
                                    $2 = tmpIdx;
                                }
                                $$ = $2;
                            }
                            | simple_expression SIGN term 
                            {
                                
                                if(checkIfUndecalred(2, $1, $3)){
                                      YYERROR;
                                }
                                $$ = checkTypes($1, $3);
                                
                                genCode(getOpCode($2), &symboltable[$$], false, &symboltable[$1], false, &symboltable[$3], false);
                            }
                            | simple_expression OR term 
                            {
                                if(checkIfUndecalred(2, $1, $3)){
                                    YYERROR;
                                }
                                $$ = checkTypes($1, $3);
                                
                                genCode("or", &symboltable[$$], false, &symboltable[$1], false, &symboltable[$3], false);
                            }
                            ;
                            
term:                       factor
                            | term MULOP factor
                            {
                                if(checkIfUndecalred(2, $1, $3)){
                                      YYERROR;
                                }
                                
                                $$ = checkTypes($1, $3);
                                genCode(getOpCode($2), &symboltable[$$], false, &symboltable[$1], false, &symboltable[$3], false);
                                
                            }
                            ;
                        
factor:                     variable
                            | ID '(' expression_list ')'
                            
                            {
                                try{
                                    if( symboltable[$1].value.compare(symboltable.getScopeName()) == 0 )
                                            handleSubprogramCall($1, $$, parameterListVect, true);
                                        else
                                            handleSubprogramCall($1, $$, parameterListVect, false);
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
                            {
                                $$ = $2;
                            }
                            | NOT factor
                            {
                                YYSTYPE zeroIdx = symboltable.lookUpPush(NUM, "0", INTEGER);
                                YYSTYPE oneIdx = symboltable.lookUpPush(NUM, "1", INTEGER);
                                YYSTYPE notResult = symboltable.pushTempVar(symboltable[zeroIdx].type);
                                string assignOneLabel = emitter.getLabel();
                                string endNotLabel = emitter.getLabel();
                                
                                labelHelper.value = assignOneLabel;
                                
                                genCode("je", &labelHelper, false, &symboltable[$2], false, &symboltable[zeroIdx], false ); //if factor == 0 jump and assign 1, else assign 0
                                genCode("mov", &symboltable[notResult], false, &symboltable[zeroIdx], false, nullptr, false);
                                labelHelper.value = endNotLabel;
                                genCode("jump", &labelHelper, false, nullptr, false, nullptr, false);
                                
                                emitter << assignOneLabel + ":";
                                genCode("mov", &symboltable[notResult], false, &symboltable[oneIdx], false, nullptr, false);
                                emitter << endNotLabel + ":";
                                
                                $$ = notResult;
                            }
                            ;
                        
%%

void yyerror(const string & s){
    cout << symboltable;
    std::cerr<< "\033[1;31mError in lnie: " << lineNumber << "\033[0m\t" << s<<endl;
}

#include <sstream>
#include <iomanip>

void handleSubprogramCall(YYSTYPE programId, YYSTYPE& resultId, vector<YYSTYPE> &arguments, bool callRecursively){
    Symbol subprogram;
    YYSTYPE programResultId = 0;
    if(callRecursively){
        symboltable.setGlobalScope();
        subprogram = symboltable[programId];
        symboltable.setLocalScope();
    }
    else{
        subprogram = symboltable[programId];
    }

    if(!(subprogram.token == FUNCTION || subprogram.token == PROCEDURE)){
        return;
    }
        
        
    if(subprogram.argumentTypes.size() != arguments.size()){
        throw std::invalid_argument("Wrong argument count, required " 
                + to_string(subprogram.argumentTypes.size()) + ", got "
                + to_string(arguments.size()));
    }

    if(subprogram.token == FUNCTION){
        programResultId = symboltable.pushTempVar(subprogram.type);
        resultId = programResultId;
    }

    pushFunctionParams(subprogram, arguments);
    
    if(subprogram.token == FUNCTION)
        emitter << "\tpush.i\t" + symboltable[programResultId].getAddress(true);
    
    emitter << "\tcall.i\t#" + subprogram.value;
    
    if(subprogram.token == FUNCTION)
        emitter << "\tincsp.i\t#" + to_string((arguments.size() + 1) * Symbol::intSize);
    else if(arguments.size() > 0)
        emitter<< "\tincsp.i\t#" + to_string((arguments.size() * Symbol::intSize));
}

void pushFunctionParams(Symbol &function, vector<YYSTYPE> &arguments){
    YYSTYPE argumentIdx = 0;
    unsigned int parameterIdx = function.argumentTypes.size() - 1;
    
    std::reverse(arguments.begin(), arguments.end());
    
    for(auto param: arguments){
        argumentIdx = param;
        
        if(symboltable[param].token == NUM){
            argumentIdx = symboltable.pushTempVar(symboltable[param].type);
            genCode("mov", &symboltable[argumentIdx], false, &symboltable[param], false, nullptr, false);
        }
        
        if(symboltable[argumentIdx].type != function.argumentTypes.at(parameterIdx)){
            argumentIdx = cast(argumentIdx, function.argumentTypes.at(parameterIdx));
        }
        
        emitter << "\tpush.i\t" + symboltable[argumentIdx].getAddress(true);
        parameterIdx--;
    }
    
}

YYSTYPE checkTypes(YYSTYPE& var1,YYSTYPE& var2){
    if(symboltable[var1].type != symboltable[var2].type){
        if(symboltable[var1].type.id == INTEGER)
            var1 =  cast(var1, symboltable[var2].type);
        else
            var2 = cast(var2, symboltable[var1].type);
    }
    return symboltable.pushTempVar(symboltable[var1].type);
}


YYSTYPE cast(YYSTYPE varIdx, Symbol::GeneralType newType){
    YYSTYPE tmpIdx = 0;
    string convOpCode;
    stringstream output;
    
    if( newType.id != INTEGER && newType.id != REAL ||
        symboltable[varIdx].type.id != INTEGER && symboltable[varIdx].type.id != REAL){
        throw std::invalid_argument("Invalid type, cannot perform implicit cast !");
    }
    
    if(newType.id == INTEGER)
        convOpCode = "\trealtoint.i";
    else
        convOpCode = "\tinttoreal.i";


    if(symboltable[varIdx].token == VAR || (symboltable[varIdx].token == NUM && newType.id == INTEGER)){
   
        tmpIdx = symboltable.pushTempVar(newType);
        output << convOpCode << ' ' << symboltable[varIdx].getAddress(false) << ',' << symboltable[tmpIdx].getAddress(false);
        emitter << output.str();
        return tmpIdx;
    }
    
    return varIdx;
}

bool checkIfUndecalred(unsigned int argCount, ...){
    va_list ids;
    va_start(ids, argCount);
    unsigned long int idx = 0;
    try{
        for(int i = 0; i < argCount; i++){
            idx = va_arg(ids, YYSTYPE);
            symboltable[idx];
        }
    }
    catch (const std::out_of_range& ex){
        yyerror("Undeclared Identifier!");
        return true;
    }
    return false;
}

string getOpCode(int opToken)
{
    switch(opToken){
        case '+':
            return "add";
        case '-':
            return "sub";
        case '*':
            return "mul";
        case '/':
            return "div";
        case '<':
            return "jl";
        case '>':
            return "jg";
        case GREATER_EQUAL:
            return "jpge";
        case LESS_EQUAL:
            return "lge";
        case MOD:
            return "mod";
        case DIV:
            return "div";
        case AND:
            return "and";
        case OR:
            return "or";
        case '=':
            return "je";
        default:
            return "unknown";
    }
}

void genCode(const string & opCode, const Symbol *result, bool resref, const Symbol* arg1, bool arg1ref,  const Symbol* arg2, bool arg2ref)
{
    stringstream output;
    stringstream debug;
    const Symbol *typeReference = result;
    output << '\t' << opCode << '.';
    
    if(result->type == LABEL && arg1 != nullptr)
        typeReference = arg1;
        
    if (typeReference->type == REAL)
        output << 'r';
    else
        output << 'i';
    
    output << '\t';
    debug << output.str().replace(0, 1, "\t;");

    if(arg1 != nullptr){
        output << arg1->getAddress(arg1ref) << ',';
        debug  << arg1->value << setw(2) << left << ',';
    }
    
    if(arg2 != nullptr){
        output << arg2->getAddress(arg2ref) << ',';
        debug << arg2->value << setw(2) << left << ',';
    }
    output << setw(5) << left << result->getAddress(resref);
    debug << setw(10) << left << result->value;
    
    //output << debug.str();
    emitter << output.str();
}
