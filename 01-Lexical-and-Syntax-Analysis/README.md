# Phase 1: Lexical Analyzer & Syntax Analyzer

## 📖 Overview
In **Phase 1**, we design and implement the first two fundamental phases of a C compiler frontend:
1. **Lexical Analysis (Scanning)** using **Flex**: Converts raw source text into a stream of categorized tokens, while stripping whitespace and tracking source line numbers.
2. **Syntax Analysis (Parsing)** using **Bison / Yacc**: Validates that the token stream adheres to the Context-Free Grammar (CFG) for a subset of the C programming language, constructs parse trees, resolves operator ambiguities (such as the classic dangling-else problem), and logs grammar production derivations.

---

## 🗂️ File Structure & Description

| File Name | Description |
| :--- | :--- |
| [`lexical_analyzer.l`](lexical_analyzer.l) | Flex specification defining regular expressions for keywords, identifiers, constants (integer & float), operators, and delimiters. |
| [`syntax_analyzer.y`](syntax_analyzer.y) | Bison/Yacc grammar specification containing BNF grammar rules, precedence rules, and semantic action routines. |
| [`symbol_info.h`](symbol_info.h) | C++ class representing token symbols, storing their name (lexeme), type (token category), and tree nodes. |
| [`input.txt`](input.txt) | Sample C input file containing function definitions, variables, control flow (`if-else`, loops), and expressions. |
| [`script.sh`](script.sh) | Shell script to automate compilation with Flex, Bison, and G++, followed by test execution. |
| `*.pdf` | Official lab specifications, grammar reference sheets, and revision notes. |

---

## ⚙️ How It Works

### 1. Lexical Analysis (`lexical_analyzer.l`)
- **Keywords**: Recognizes standard C keywords such as `if`, `else`, `for`, `while`, `int`, `float`, `void`, `return`, and built-in functions like `println`.
- **Numbers**: Regular definitions distinguish between:
  - `const_int`: Sequences of digits (`[0-9]+`).
  - `const_float`: Floating-point numbers including exponential notation (e.g., `3.14`, `1.5e-3`).
- **Identifiers**: Matches alphanumeric variable and function names starting with a letter or underscore (`[a-zA-Z_][a-zA-Z0-9_]*`).
- **Operators & Punctuation**: Distinguishes arithmetic operators (`ADDOP`, `MULOP`), relational operators (`RELOP`), logical operators (`LOGICOP`), increment/decrement (`INCOP`, `DECOP`), assignment (`ASSIGNOP`), and punctuation (`(`, `)`, `{`, `}`, `[`, `]`, `,`, `;`).
- **Line Tracking**: Automatically increments `line_num` on `\n` to report accurate line numbers during parsing.

### 2. Syntax Analysis (`syntax_analyzer.y`)
The parser accepts tokens passed by the lexer and applies CFG rules for:
- **Program Structure**: Programs consisting of global declarations and function definitions.
- **Function Prototypes & Bodies**: Validating function headers, parameter lists, and compound statements enclosed in `{ ... }`.
- **Statements**: Variable declarations, assignment expressions, conditional statements (`if-else`), iterative statements (`for`, `while`), and `return` statements.
- **Dangling-Else Resolution**: Uses `%nonassoc LOWER_THAN_ELSE` and `%nonassoc ELSE` to prioritize shift over reduce, binding `else` to the closest open `if`.
- **Derivation Logging**: Every time a grammar production reduces, the rule and matched subtree text are written to `outlog` (generated log file).

---

## 🚀 How to Run

### Prerequisites
- GCC / G++ compiler
- Flex (Fast Lexical Analyzer)
- Bison / Yacc (Parser Generator)

### Automated Execution (Linux / macOS / Git Bash / WSL)
```bash
bash script.sh
```

### Manual Step-by-Step Compilation
```bash
# Step 1: Generate parser source and header
yacc -d -y --debug --verbose syntax_analyzer.y

# Step 2: Compile parser
g++ -w -c -o y.o y.tab.c

# Step 3: Generate scanner source
flex lexical_analyzer.l

# Step 4: Compile scanner
g++ -fpermissive -w -c -o l.o lex.yy.c

# Step 5: Link parser and scanner into executable
g++ y.o l.o -o a.out

# Step 6: Run on test input
./a.out input.txt
```

---

## 📋 Sample Input & Output

### Sample Input (`input.txt`)
```c
int func(int a, float b) {
    return a + b;
}

void main() {
    int a, b;
    a = 10;
    b = 20;
    if (a < b) {
        println(a);
    } else {
        println(b);
    }
}
```

### Derivation Log Snippet (`log.txt`)
```text
At line no: 1 type_specifier : INT 
int

At line no: 1 param_list : type_specifier ID 
int a

At line no: 1 func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement 
int func(int a,float b)
...
At line no: 15 start : program 
...
Total lines: 15
```
