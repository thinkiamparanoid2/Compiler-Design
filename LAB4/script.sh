#!/bin/bash

# Clean previous build artifacts
rm -f y.tab.c y.tab.h y.output lex.yy.c y.o l.o two_pass_compiler two_pass_compiler.exe code.txt log.txt error.txt

echo "Step 1: Running Yacc/Bison on intermediate_code_generator.y..."
yacc -d -y --debug --verbose intermediate_code_generator.y
echo "Generated parser C file (y.tab.c) and header file (y.tab.h)"

echo "Step 2: Compiling parser object file..."
g++ -w -c -o y.o y.tab.c

echo "Step 3: Running Flex on lexical_analyzer.l..."
flex lexical_analyzer.l
echo "Generated scanner C file (lex.yy.c)"

echo "Step 4: Compiling scanner object file..."
g++ -fpermissive -w -c -o l.o lex.yy.c

echo "Step 5: Linking Two-Pass Compiler executable..."
g++ y.o l.o -o two_pass_compiler

echo "Step 6: Running Two-Pass Compiler on InputOutput/input1.c..."
./two_pass_compiler InputOutput/input1.c

echo ""
echo "Compilation and execution completed!"
echo "============ Generated Three-Address Code (code.txt) ============"
cat code.txt