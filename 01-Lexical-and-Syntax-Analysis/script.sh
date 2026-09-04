#!/bin/bash

# Clean previous build artifacts
rm -f y.tab.c y.tab.h y.output lex.yy.c y.o l.o a.out a.exe

echo "Step 1: Running Yacc/Bison on syntax_analyzer.y..."
yacc -d -y --debug --verbose syntax_analyzer.y
echo "Generated the parser C file (y.tab.c) and header file (y.tab.h)"

echo "Step 2: Compiling parser object file..."
g++ -w -c -o y.o y.tab.c

echo "Step 3: Running Flex on lexical_analyzer.l..."
flex lexical_analyzer.l
echo "Generated the scanner C file (lex.yy.c)"

echo "Step 4: Compiling scanner object file..."
g++ -fpermissive -w -c -o l.o lex.yy.c

echo "Step 5: Linking parser and scanner..."
g++ y.o l.o -o a.out

echo "Step 6: Running parser on input.txt..."
./a.out input.txt

echo "Execution finished. Check log.txt for parser derivation logs."
