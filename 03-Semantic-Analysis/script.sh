#!/bin/bash

# Clean previous build artifacts
rm -f y.tab.c y.tab.h y.output lex.yy.c y.o l.o a.out a.exe log.txt error.txt

echo "Step 1: Running Yacc/Bison on semantic_analyzer.y..."
yacc -d -y --debug --verbose semantic_analyzer.y
echo "Generated parser C file (y.tab.c) and header file (y.tab.h)"

echo "Step 2: Compiling parser object..."
g++ -w -c -o y.o y.tab.c

echo "Step 3: Running Flex on lexical_analyzer.l..."
flex lexical_analyzer.l
echo "Generated scanner C file (lex.yy.c)"

echo "Step 4: Compiling scanner object..."
g++ -fpermissive -w -c -o l.o lex.yy.c

echo "Step 5: Linking parser and scanner..."
g++ y.o l.o -o a.out

echo "Step 6: Running semantic analyzer on InputOutput/input1.c..."
./a.out InputOutput/input1.c

echo "Execution finished."
echo "=== Error Log (error.txt) ==="
cat error.txt
