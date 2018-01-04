objects = lexer.o main.o
cc = g++
flags = -pedantic -Wall -Wredundant-decls -Wmissing-declarations -flto -Wodr

compiler: $(objects)
	$(cc) $(flags) -o compiler $(objects)

lexer.o: lexer.cpp global.hpp

main.o: main.cpp global.hpp

lexer.cpp: lexer.l
	flex -o lexer.cpp lexer.l

.PHONY: clean

clean:
	-rm -f compiler $(objects) lexer.cpp
