objects = lexer.o parser.o Symbol.o SymbolTableManager.o Emitter.o main.o
cc = g++
flags = -pedantic -Wall -Wredundant-decls -Wmissing-declarations -flto -Wodr

compiler: $(objects)
	$(cc) $(flags) -g -o compiler $(objects)

lexer.o: lexer.cpp global.hpp
	$(cc) -g -c -o lexer.o lexer.cpp

main.o: main.cpp global.hpp
	$(cc) $(flags) -g -c -o main.o main.cpp

parser.o: parser.cpp parser.hpp global.hpp
	$(cc) -g -c -o parser.o parser.cpp

global.hpp: parser.hpp SymbolTableManager.h Emitter.h Symbol.h

Emitter.o: Emitter.cpp Emitter.h
	$(cc) $(flags) -g -c -o Emitter.o Emitter.cpp

SymbolTableManager.o: SymbolTableManager.cpp SymbolTableManager.h Symbol.h
	$(cc) $(flags) -g -c -o SymbolTableManager.o SymbolTableManager.cpp
	
Symbol.o: Symbol.cpp Symbol.h parser.hpp
	$(cc) $(flags) -g -c -o Symbol.o Symbol.cpp

parser.cpp parser.hpp: parser.y
	bison -d -o parser.cpp parser.y

lexer.cpp: lexer.l
	flex -o lexer.cpp lexer.l




.PHONY: clean

clean:
	-rm -f compiler $(objects) lexer.cpp parser.cpp parser.hpp
