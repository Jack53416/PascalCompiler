objects = lexer.o parser.o main.o
cc = g++
flags = -pedantic -Wall -Wredundant-decls -Wmissing-declarations -flto -Wodr

compiler: $(objects)
	$(cc) $(flags) -o compiler $(objects)

lexer.o: lexer.cpp global.hpp

main.o: main.cpp global.hpp

parser.o: parser.cpp parser.hpp

global.hpp: parser.hpp

parser.cpp parser.hpp: parser.y
	bison -d -o parser.cpp parser.y

lexer.cpp: lexer.l
	flex -o lexer.cpp lexer.l

.PHONY: clean

clean:
	-rm -f compiler $(objects) lexer.cpp parser.cpp parser.hpp
