# CSE420 Lab 4: Intermediate Code Generation (Two-Pass Compiler)
## 🎓 The Friendly, Step-by-Step Viva Revision Guide

---

# Table of Contents
1. [The 30-Second Big Picture](#1-the-30-second-big-picture)
2. [C++ Tip: Why `find(name) != end()` Means "FOUND"](#2-c-tip-why-findname--end-means-found)
3. [Task 1: Constants (`ConstNode`)](#task-1-constants-constnode)
4. [Task 2: Variables & Register Caching (`VarNode`)](#task-2-variables--register-caching-varnode)
5. [Task 3: Binary Operations (`BinaryOpNode` for `+`, `-`, `*`, `/`, `%`)](#task-3-binary-operations-binaryopnode)
6. [Task 4: Unary Operations (`UnaryOpNode` for `-`, `+`, `!`)](#task-4-unary-operations-unaryopnode)
7. [Task 5: Assignments (`AssignNode` for `x = ...`)](#task-5-assignments-assignnode)
8. [Task 6: Array Access & Byte-Offset Scaling (`a[i]` and `a[i] = rhs`)](#task-6-array-access--byte-offset-scaling-ai-and-ai--rhs)
9. [Task 7: Function Calls (`FuncCallNode`)](#task-7-function-calls-funccallnode)
10. [Task 8: Expression Statements (`ExprStmtNode`)](#task-8-expression-statements-exprstmtnode)
11. [Task 9: Code Blocks (`BlockNode` for `{ ... }`)](#task-9-code-blocks-blocknode-for----)
12. [Task 10: If & If-Else Branching (`IfNode`)](#task-10-if--if-else-branching-ifnode)
13. [Task 11: While Loops (`WhileNode`)](#task-11-while-loops-whilenode)
14. [Task 12: For Loops (`ForNode`)](#task-12-for-loops-fornode)
15. [Task 13: Return Statements (`ReturnNode`)](#task-13-return-statements-returnnode)
16. [Task 14: Variable Declarations (`DeclNode`)](#task-14-variable-declarations-declnode)
17. [Task 15: Two-Pass Driver (`main`)](#task-15-two-pass-driver-main)
18. [Top 15 Viva Questions & Answers](#18-top-15-viva-questions--answers)

---

# 1. The 30-Second Big Picture

In this lab, you built a **Two-Pass Compiler**:
1. **Pass 1 (Flex & Bison):** Reads C code, checks syntax and semantics (types, scopes), and builds a tree structure in memory called the **Abstract Syntax Tree (AST)**.
2. **Pass 2 (`ThreeAddrCodeGenerator`):** If there are zero errors, it walks the AST from bottom to top and prints simple **Three-Address Code (TAC)** into `code.txt`.

---

# 2. C++ Tip: Why `find(name) != end()` Means "FOUND"

In C++ `std::map`:
- `.end()` is **NOT** the last element. It is a special **"NOT FOUND" / "OUT OF BOUNDS"** marker at the very end.
- When you run `symbol_to_temp.find("a")`:
  - If `"a"` **IS in the map**: `find()` stops at `"a"`. Because it stopped early, it is **NOT equal to `.end()`**. So `find() != end()` is **`true`** (**FOUND / IN CACHE**).
  - If `"a"` **is NOT in the map**: `find()` reaches the end without finding anything, returning `.end()`. So `find() == end()` is **`true`** (**NOT FOUND**).

---

# Task 1: Constants (`ConstNode`)

### 1. The Scenario
The compiler encounters a raw number in code: `10`

### 2. What it does
Loads the number into a fresh temporary register:
```text
t0 = 10
```

### 3. Code & Execution
```cpp
// ast.h lines 88–101
string temp = "t" + to_string(temp_count++); // temp = "t0"
outcode << temp << " = " << value << endl;   // prints "t0 = 10"
return temp;                                 // returns "t0"
```

---

# Task 2: Variables & Register Caching (`VarNode`)

### 1. The Scenario
The compiler encounters a variable: `a`

### 2. What it does
Loads `a` into a temporary register (`t0 = a`) and saves it in a notebook (`symbol_to_temp["a"] = "t0"`). If `a` is used again, it reuses `"t0"` instead of loading it twice!

### 3. Code & Execution
```cpp
// ast.h lines 63–83
if (symbol_to_temp.find(name) != symbol_to_temp.end()) {
    return symbol_to_temp[name]; // Already loaded! Return "t0"
}
outcode << temp << " = " << name << endl; // First time: prints "t0 = a"
symbol_to_temp[name] = temp;              // Save in notebook
return temp;
```

---

# Task 3: Binary Operations (`BinaryOpNode`)

### 1. The Scenario
Two operands combined with an operator: `a + b` or `b * 2`

### 2. What it does
1. Asks the left side to calculate itself $\rightarrow$ `left_val = "t0"` (`t0 = a`)
2. Asks the right side to calculate itself $\rightarrow$ `right_val = "t1"` (`t1 = b`)
3. Picks a new result register $\rightarrow$ `temp = "t2"`
4. Emits: `t2 = t0 + t1`
5. Returns `"t2"`.

---

# Task 4: Unary Operations (`UnaryOpNode`)

### 1. The Scenario
One operand with a unary sign or logical NOT: `-a` or `!flag`

### 2. What it does
1. Asks the operand to calculate itself $\rightarrow$ `expr_val = "t0"` (`t0 = a`)
2. Picks a new result register $\rightarrow$ `temp = "t1"`
3. Emits: `t1 = -t0` (or `t1 = !t0`)
4. Returns `"t1"`.

---

# Task 5: Assignments (`AssignNode`)

### 1. The Scenario
Writing a value into a variable: `a = 10;` or `x = a + b;`

### 2. What it does
1. Calculates whatever is on the Right-Hand Side (RHS) $\rightarrow$ `rhs_val = "t0"`
2. Writes the value into the Left-Hand Side (LHS) variable:
   ```text
   a = t0
   ```

---

# Task 6: Array Access & Byte-Offset Scaling (`a[i]` and `a[i] = rhs`)

### 1. The Scenario & Why Multiply by 4 or 8?
In physical computer memory, RAM is **byte-addressed**:
- `int` = 4 bytes
- `float`/`double` = 8 bytes
To access `a[i]`, the memory location is: $\text{Byte Offset} = i \times 4$.

### 2. What it does
```c
x = f[i];    // Read
f[i] = 10;   // Write
```
**Generated TAC:**
```text
// Reading from f[i]
t0 = i
t1 = t0 * 4      // Scaled byte offset
t2 = f[t1]       // Read from memory
x = t2

// Writing to f[i]
t3 = 10
t4 = i
t5 = t4 * 4      // Scaled byte offset
f[t5] = t3       // Write to memory
```

---

# Task 7: Function Calls (`FuncCallNode`)

### 1. The Scenario
Calling a function: `c = func(a, b);`

### 2. What it does
1. Evaluates each argument (`a` $\rightarrow$ `t0`, `b` $\rightarrow$ `t1`).
2. Pushes parameters:
   ```text
   param t0
   param t1
   ```
3. Calls function and catches the return value in `t2`:
   ```text
   t2 = call func, 2
   c = t2
   ```

---

# Task 8: Expression Statements (`ExprStmtNode`)

### 1. The Scenario
An expression followed by a semicolon: `a = 5;`

### 2. What it does
Acts as an **adapter/wrapper** that turns an expression into a standalone statement line inside a `{ ... }` block.

---

# Task 9: Code Blocks (`BlockNode` for `{ ... }`)

### 1. The Scenario
Multiple statements grouped inside curly braces `{ ... }`.

### 2. What it does
Stores a list of statements (`vector<StmtNode*>`) and executes them one by one from top to bottom.

---

# Task 10: If & If-Else Branching (`IfNode`)

### 1. The Scenario
```c
if (a > 10) {
    x = 1;
} else {
    x = 2;
}
```

### 2. What it does (Decision Jumps with Labels)
1. Evaluates condition: `t2 = a > 10`
2. Emits decision jumps:
   ```text
   if t2 goto L0
   goto L1
   ```
3. Emits True Block under `L0:`:
   ```text
   L0:
   x = 1
   goto L2    // Skip else block!
   ```
4. Emits False Block under `L1:`:
   ```text
   L1:
   x = 2
   ```
5. Emits End Label: `L2:`

---

# Task 11: While Loops (`WhileNode`)

### 1. The Scenario
```c
while (c > 0) {
    c--;
}
```

### 2. How CPUs Handle a While Loop
A loop is just an `if` statement with a **jump back to the top**!
1. `L_start:` (Loop Header bookmark)
2. Evaluate condition (`c > 0`).
3. If true $\rightarrow$ `if cond goto L_body`
4. If false $\rightarrow$ `goto L_end` (break out of loop)
5. `L_body:` $\rightarrow$ execute `c--`
6. `goto L_start` $\rightarrow$ jump back to top!
7. `L_end:` $\rightarrow$ exit label.

### 3. Generated TAC:
```text
L6:
t30 = 0
t31 = c > t30
if t31 goto L7
goto L8
L7:
t33 = 1
t34 = c - t33
c = t34
goto L6
L8:
```

---

# Task 12: For Loops (`ForNode`)

### 1. The Scenario
```c
for (i = 0; i < 10; i++) {
    a = c;
}
```

### 2. How CPUs Handle a For Loop
A `for` loop has 4 parts: `for (init; condition; update) body`
1. **`init` (`i = 0`)** runs **once** before the loop starts.
2. **`L_start:`** loop header bookmark.
3. **`condition` (`i < 10`)** is tested:
   - If true $\rightarrow$ `if cond goto L_body`
   - If false $\rightarrow$ `goto L_end`
4. **`L_body:`** runs the body (`a = c;`).
5. **`update` (`i++`)** runs at the end of each iteration.
6. **`goto L_start`** jumps back to the condition check.
7. **`L_end:`** exit label.

### 3. Generated TAC:
```text
t11 = 0
i = t11
L0:
t12 = i
t13 = 10
t14 = t12 < t13
if t14 goto L1
goto L2
L1:
a = c
t20 = 1
t21 = i + t20
i = t21
goto L0
L2:
```

---

# Task 13: Return Statements (`ReturnNode`)

### 1. The Scenario
```c
return a + b;
```
or for void:
```c
return;
```

### 2. What it does
- If returning an expression: calculates `a + b` into `t2`, and emits:
  ```text
  return t2
  ```
- If returning void: emits:
  ```text
  return
  ```

---

# Task 14: Variable Declarations (`DeclNode`)

### 1. The Scenario
```c
int a, b, f[10];
```

### 2. What it does
In basic Three-Address Code, declarations do not perform arithmetic. Instead, `DeclNode` prints **documentation comments** in `code.txt` to show what variables exist:
```text
// Declaration: int a
// Declaration: int b
// Declaration: int f[10]
```

---

# Task 15: Two-Pass Driver (`main`)

### What it does in `main()`
```cpp
// PASS 1: Flex & Bison parse code and construct AST in memory
yyparse();

// PASS 2: Only generate TAC if there were ZERO errors!
if (errors == 0 && ast_root) {
    ThreeAddrCodeGenerator tacGen(ast_root, outcode);
    tacGen.generate(); // Emits clean TAC to code.txt
} else {
    outcode << "// Three-Address Code generation skipped due to errors" << endl;
}
```

---

# 18. Top 15 Viva Questions & Answers

1. **What is Three-Address Code?**
   > An intermediate language where every instruction has at most 3 operand addresses (at most 2 inputs, 1 output).
2. **Why use an AST instead of printing code while parsing?**
   > Decouples syntax from code generation, preserves operator precedence naturally, handles forward control-flow jumps easily, and prevents generating partial code if errors exist.
3. **Why did you multiply array indices by 4 or 8?**
   > Computer memory is byte-addressed. An `int` occupies 4 bytes and a `float`/`double` occupies 8 bytes. Accessing `a[i]` requires computing the byte offset: $i \times \text{sizeof(type)}$.
4. **Why does `find(name) != end()` mean FOUND in C++?**
   > In `std::map`, `.end()` is an invalid sentinel representing "NOT FOUND". If a key exists, `find()` stops before `.end()`, so `find() != end()` is true.
5. **What is `symbol_to_temp`?**
   > A local register cache within a function that remembers which temporary register holds a variable, avoiding redundant load instructions.
6. **Why is `symbol_to_temp.clear()` called in `FuncDeclNode`?**
   > Registers and local variables belong to one function scope and must not leak into other functions.
7. **How do function calls work in TAC?**
   > Evaluate arguments into temporaries, emit `param tX` for each, then emit `tY = call func, count`.
8. **How does `if-else` work in TAC?**
   > Evaluates condition, uses `if cond goto L_true` and `goto L_false`, executes then-block under `L_true:`, jumps to `L_end`, executes else-block under `L_false:`, and ends at `L_end:`.
9. **How does a `while` loop work in TAC?**
   > Marks `L_start:`, tests condition (`if cond goto L_body` and `goto L_end`), executes body under `L_body:`, jumps back via `goto L_start`, and exits at `L_end:`.
10. **How does a `for` loop work in TAC?**
    > Runs `init` once $\rightarrow$ `L_start:` $\rightarrow$ tests condition $\rightarrow$ executes `body` under `L_body:` $\rightarrow$ runs `update` $\rightarrow$ `goto L_start` $\rightarrow$ exits at `L_end:`.
11. **How are `x++` and `x--` handled?**
    > Converted into assignment `x = x + 1` or `x = x - 1` using `AssignNode` wrapping `BinaryOpNode` and `ConstNode(1)`.
12. **What happens if there is an error in input code?**
    > `errors` counter $> 0$. Pass 2 is completely skipped, leaving `code.txt` with an error notice and recording errors in `error.txt`.
13. **What is the difference between AST and Parse Tree (CST)?**
    > A Parse Tree contains all grammar tokens including semicolons, commas, and parentheses. An AST strips away syntax clutter and keeps only semantic operators and operands.
14. **How is array assignment `a[i] = rhs` handled?**
    > `generate_index_code` computes `tX = i * 4`, and `AssignNode` emits `a[tX] = rhs_temp`.
15. **How are unique temporary and label IDs created?**
    > Integer counters `temp_count` and `label_count` are incremented (`"t" + to_string(temp_count++)` and `"L" + to_string(label_count++)`) to guarantee unique IDs.
