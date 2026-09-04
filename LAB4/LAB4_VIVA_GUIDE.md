# CSE420 Lab 4: Intermediate Code Generation (Two-Pass Compiler)
## 🎓 The Friendly, Visual Viva Master Guide (Complete Code Walkthrough)

---

# Table of Contents
1. [The 30-Second Big Picture](#1-the-30-second-big-picture)
2. [C++ STL Deep-Dive: Why `find(name) != end()` Means "FOUND"](#2-c-stl-deep-dive-why-findname--end-means-found)
3. [Task 1: Constants (`ConstNode`)](#task-1-constants-constnode)
4. [Task 2: Variables & Register Caching (`VarNode`)](#task-2-variables--register-caching-varnode)
5. [Task 3: Array Access & Byte-Offset Scaling (`VarNode::generate_index_code`)](#task-3-array-access--byte-offset-scaling-varnodegenerate_index_code)
6. [Task 4: Binary Arithmetic & Relational Operations (`BinaryOpNode`)](#task-4-binary-arithmetic--relational-operations-binaryopnode)
7. [Task 5: Unary Operations (`UnaryOpNode`)](#task-5-unary-operations-unaryopnode)
8. [Task 6: Postfix Increment & Decrement (`++`, `--`)](#task-6-postfix-increment--decrement---)
9. [Task 7: Variable & Array Assignments (`AssignNode`)](#task-7-variable--array-assignments-assignnode)
10. [Task 8: Expression Statement Adapter (`ExprStmtNode`)](#task-8-expression-statement-adapter-exprstmtnode)
11. [Task 9: Code Blocks (`BlockNode` for `{ ... }`)](#task-9-code-blocks-blocknode-for----)
12. [Task 10: If & If-Else Branching (`IfNode`)](#task-10-if--if-else-branching-ifnode)
13. [Task 11: While Loops (`WhileNode`)](#task-11-while-loops-whilenode)
14. [Task 12: For Loops (`ForNode`)](#task-12-for-loops-fornode)
15. [Task 13: Return Statements (`ReturnNode`)](#task-13-return-statements-returnnode)
16. [Task 14: Variable Declarations (`DeclNode`)](#task-14-variable-declarations-declnode)
17. [Task 15: Function Calls (`FuncCallNode`)](#task-15-function-calls-funccallnode)
18. [Task 16: Function Definitions & Scope Clearing (`FuncDeclNode`)](#task-16-function-definitions--scope-clearing-funcdeclnode)
19. [Task 17: Two-Pass Driver & Error Handling (`main`)](#task-17-two-pass-driver--error-handling-main)
20. [Top 15 Master Viva Questions & Answers](#20-top-15-master-viva-questions--answers)

---

# 1. The 30-Second Big Picture

In this lab, you built a **Two-Pass Compiler**:
$$\text{Source Code (.c)} \xrightarrow{\text{Pass 1}} \text{AST in Memory + Symbol Table} \xrightarrow{\text{Pass 2 (if 0 errors)}} \text{Three-Address Code (code.txt)}$$

1. **Pass 1 (Flex & Bison):** Reads C code, checks syntax and semantics (types, scopes), and constructs an **Abstract Syntax Tree (AST)** in memory.
2. **Pass 2 (`ThreeAddrCodeGenerator`):** If there are zero errors, it walks the AST from bottom to top and prints formatted **Three-Address Code (TAC)** into `code.txt`.

---

# 2. C++ STL Deep-Dive: Why `find(name) != end()` Means "FOUND"

In C++ `std::map<string, string>`:
- `.end()` is **NOT** the last element! It is a special **"NOT FOUND / OUT OF BOUNDS" sentinel pointer** at the very end of the map.

```
  [ "a" : "t0" ] ──► [ "b" : "t1" ] ──► [ "c" : "t2" ] ──► [ .end() (Sentinel: NOT FOUND) ]
         ▲
         │
   find("a") stops HERE (Valid match! Not equal to .end())
```

- When you run `symbol_to_temp.find("a")`:
  - If `"a"` **IS in the map**: `find()` stops at `"a"`. Because it stopped early at a valid element, it is **NOT equal to `.end()`**. So `find() != end()` evaluates to **`true`** (**FOUND IN CACHE**).
  - If `"a"` **is NOT in the map**: `find()` searches the entire map, finds nothing, and falls off into `.end()`. So `find() == end()` evaluates to **`true`** (**NOT FOUND**).

---

# Task 1: Constants (`ConstNode`)

### The Concept
When the compiler sees a number like `10` or `3.14`, it cannot leave it as a raw literal in Three-Address Code. It loads it into a fresh temporary register.

### Code & Visual Breakdown
```cpp
class ConstNode : public ExprNode {
private:
    string value; // Stores "10" or "3.14"

public:
    ConstNode(string val, string type) : ExprNode(type), value(val) {}
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // 1. Pick a new temporary register (e.g., "t0")
        string temp = "t" + to_string(temp_count++);
        
        // 2. Emit TAC instruction to code.txt
        outcode << temp << " = " << value << endl;
        
        // 3. Return "t0" so whoever asked for the number knows where it is stored
        return temp;
    }
};
```

### Live Trace:
- Input: `10`
- Emits: `t0 = 10`
- Returns: `"t0"`

---

# Task 2: Variables & Register Caching (`VarNode`)

### The Concept (The Notebook / Register Cache)
When a variable `a` is read, we load it into a temporary: `t0 = a`. 
To avoid generating redundant duplicate loads (e.g. for `a + a`), we use a notebook (`symbol_to_temp`) to remember that `a` is already sitting in `t0`.

### Code & Visual Breakdown
```cpp
string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                    int& temp_count, int& label_count) const override {
    string temp = "t" + to_string(temp_count++);

    if (index) {
        // Handled in Task 3 (Array Access)
    } else {
        // 1. Check the Notebook: Is 'a' already in a register?
        if (symbol_to_temp.find(name) != symbol_to_temp.end()) {
            return symbol_to_temp[name]; // YES! Return existing "t0" (no new load!)
        }
        
        // 2. First time seeing 'a': Emit load instruction
        outcode << temp << " = " << name << endl;
        
        // 3. Record in Notebook: symbol_to_temp["a"] = "t0"
        symbol_to_temp[name] = temp;
    }
    return temp;
}
```

### Live Trace for `a + a`:
1. 1st `a` $\rightarrow$ Emits `t0 = a`, records `symbol_to_temp["a"] = "t0"`, returns `"t0"`.
2. 2nd `a` $\rightarrow$ Finds `"a"` in notebook, immediately returns `"t0"` (no duplicate load emitted!).

---

# Task 3: Array Access & Byte-Offset Scaling (`VarNode::generate_index_code`)

### The Concept: Why Multiply by 4 or 8?
Computer RAM is **byte-addressed**:
- `int` = 4 bytes
- `float`/`double` = 8 bytes
To access `a[i]`, the memory location from the start of the array is: $\text{Byte Offset} = i \times 4$.

### Code & Visual Breakdown
```cpp
string generate_index_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                          int& temp_count, int& label_count) const {
    if (index) {
        // 1. Calculate the index expression 'i'
        string idx_temp = index->generate_code(outcode, symbol_to_temp, temp_count, label_count);

        // 2. Pick scale factor (4 for int, 8 for float/double)
        string scale_temp = "t" + to_string(temp_count++);
        int scale_factor = 4;
        if (node_type == "float" || node_type == "double") scale_factor = 8;

        // 3. Emit byte-offset calculation: t1 = t0 * 4
        outcode << scale_temp << " = " << idx_temp << " * " << scale_factor << endl;

        // 4. Return the byte-offset register ("t1")
        return scale_temp;
    }
    return "";
}
```

### Live Trace for Array Read (`x = f[i];`):
```text
t0 = i
t1 = t0 * 4      // Scaled byte offset
t2 = f[t1]       // Read from memory
x = t2
```

---

# Task 4: Binary Arithmetic & Relational Operations (`BinaryOpNode`)

### The Concept (2 Operands: Left and Right)
Evaluates `left` operand, evaluates `right` operand, and emits `t_result = left_temp op right_temp`.

### Code & Visual Breakdown
```cpp
class BinaryOpNode : public ExprNode {
private:
    string op;       // "+", "-", "*", "/", ">", "==", "&&"
    ExprNode* left;  // Left child
    ExprNode* right; // Right child

public:
    BinaryOpNode(string op, ExprNode* left, ExprNode* right, string result_type)
        : ExprNode(result_type), op(op), left(left), right(right) {}
    
    string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                        int& temp_count, int& label_count) const override {
        // 1. Calculate left side
        string left_val = left->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        // 2. Calculate right side
        string right_val = right->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        
        // 3. Pick fresh result register
        string temp = "t" + to_string(temp_count++);
        
        // 4. Emit math/relational instruction
        outcode << temp << " = " << left_val << " " << op << " " << right_val << endl;
        
        return temp;
    }
};
```

### Live Trace for `a + b * 2`:
```text
t0 = a
t1 = b
t2 = 2
t3 = t1 * t2
t4 = t0 + t3
```

---

# Task 5: Unary Operations (`UnaryOpNode`)

### The Concept (1 Operand)
Evaluates single operand and emits `t_result = op t_operand` (e.g. `-a` or `!flag`).

### Code & Visual Breakdown
```cpp
string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                    int& temp_count, int& label_count) const override {
    // 1. Calculate operand
    string expr_val = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
    
    // 2. Pick result register
    string temp = "t" + to_string(temp_count++);
    
    // 3. Emit unary instruction
    outcode << temp << " = " << op << expr_val << endl;
    
    return temp;
}
```

### Live Trace:
- Input: `!a`
- Emits: `t0 = a`, `t1 = !t0`
- Returns: `"t1"`

---

# Task 6: Postfix Increment & Decrement (`++`, `--`)

### The Concept
In our AST design, `c++` and `c--` are transformed by the parser into an assignment: `c = c + 1` or `c = c - 1`.

### Parser Grammar Action (`22201161.y` lines 1228–1259)
```yacc
factor : variable INCOP 
    {
        VarNode* varNode = (VarNode*)$1->get_ast_node();
        ConstNode* oneNode = new ConstNode("1", "int");
        BinaryOpNode* addNode = new BinaryOpNode("+", varNode, oneNode, $1->getvartype());
        AssignNode* assignNode = new AssignNode(varNode, addNode, $1->getvartype());
        $$->set_ast_node(assignNode);
    }
```

### Live Trace for `c--;`:
```text
t33 = 1
t34 = t15 - t33
c = t34
```

---

# Task 7: Variable & Array Assignments (`AssignNode`)

### The Concept
Calculates RHS value first.
- If LHS is a **scalar variable**: writes `a = rhs_temp` and updates the register notebook so future reads get the new value!
- If LHS is an **array cell**: computes byte offset and writes `arr[offset] = rhs_temp`.

### Code & Visual Breakdown
```cpp
string generate_code(ofstream& outcode, map<string, string>& symbol_to_temp,
                    int& temp_count, int& label_count) const override {
    // 1. Calculate Right-Hand Side first
    string rhs_val = rhs->generate_code(outcode, symbol_to_temp, temp_count, label_count);

    // Case A: Array Write (e.g. arr[i] = 10;)
    if (lhs->has_index()) {
        string idx_val = lhs->generate_index_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << lhs->get_name() << "[" << idx_val << "] = " << rhs_val << endl;
    } 
    // Case B: Scalar Variable Write (e.g. a = 10;)
    else {
        outcode << lhs->get_name() << " = " << rhs_val << endl;
        
        // Update Notebook if variable was previously tracked!
        if (symbol_to_temp.find(lhs->get_name()) != symbol_to_temp.end()) {
            symbol_to_temp[lhs->get_name()] = rhs_val;
        }
    }
    return rhs_val;
}
```

### Live Trace:
- For `a = 10;` $\rightarrow$ `t0 = 10`, `a = t0`
- For `f[i] = 10;` $\rightarrow$ `t0 = 10`, `t1 = i`, `t2 = t1 * 4`, `f[t2] = t0`

---

# Task 8: Expression Statement Adapter (`ExprStmtNode`)

### The Concept: How does the compiler know something is a statement?
An expression like `a = 5` is just a calculation (`ExprNode`).
When the parser sees a **semicolon `;`** (`a = 5;`), it wraps the expression into an **`ExprStmtNode`** envelope so it can be added into `{ ... }` statement lists!

### Parser Rule (`22201161.y` lines 668–678)
```yacc
expression_statement : expression SEMICOLON 
    {
        ExprNode* exprNode = (ExprNode*)$1->get_ast_node();
        ExprStmtNode* stmtNode = new ExprStmtNode(exprNode);
        $$->set_ast_node(stmtNode);
    }
```

### Code in `ast.h`
```cpp
class ExprStmtNode : public StmtNode {
private:
    ExprNode* expr;

public:
    ExprStmtNode(ExprNode* e) : expr(e) {}
    ~ExprStmtNode() { if(expr) delete expr; }
    
    string generate_code(...) const override {
        if (expr) {
            return expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        }
        return ""; // Empty statement (just a semicolon ;)
    }
};
```

---

# Task 9: Code Blocks (`BlockNode` for `{ ... }`)

### The Concept
When the parser sees curly braces **`{` and `}`**, it creates a **`BlockNode`** folder. Every statement inside the braces is added to the folder's list. When generating code, it simply runs all statements from top to bottom.

### Code & Visual Breakdown
```cpp
class BlockNode : public StmtNode {
private:
    vector<StmtNode*> statements; // List of statements inside { ... }

public:
    void add_statement(StmtNode* stmt) {
        if (stmt) statements.push_back(stmt);
    }
    
    string generate_code(...) const override {
        for (auto stmt : statements) {
            if (stmt) {
                stmt->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            }
        }
        return "";
    }
};
```

---

# Task 10: If & If-Else Branching (`IfNode`)

### The Concept: Decision Jumps with 3 Labels
CPUs don't have curly braces; they use bookmarks (Labels: `L0, L1, L2`) and jumps (`goto`).

```
       Evaluate: Is a > 10?
          /             \
    [ If True ]     [ If False ]
         │               │
      goto L0         goto L1
         │               │
         ▼               ▼
     [ L0: ]          [ L1: ]
     x = 1            x = 2
     goto L2             │
         │               │
         └───────┬───────┘
                 ▼
              [ L2: ] (Continue program)
```

### Code & Visual Breakdown
```cpp
string generate_code(...) const override {
    // 1. Allocate 3 bookmark labels
    string label_true  = "L" + to_string(label_count++); // "L0"
    string label_false = "L" + to_string(label_count++); // "L1"
    string label_end   = "L" + to_string(label_count++); // "L2"

    // 2. Evaluate condition (a > 10)
    string cond_val = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);

    // 3. Emit decision jumps
    outcode << "if " << cond_val << " goto " << label_true << endl;
    outcode << "goto " << label_false << endl;

    // 4. True Branch (then_block)
    outcode << label_true << ":" << endl;
    if (then_block) then_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);
    outcode << "goto " << label_end << endl; // Skip else block!

    // 5. False Branch (else_block)
    outcode << label_false << ":" << endl;
    if (else_block) else_block->generate_code(outcode, symbol_to_temp, temp_count, label_count);

    // 6. Common End Label
    outcode << label_end << ":" << endl;
    return "";
}
```

### Live Trace for `if (a > 10) { x = 1; } else { x = 2; }`:
```text
t0 = a
t1 = 10
t2 = t0 > t1
if t2 goto L0
goto L1
L0:
t3 = 1
x = t3
goto L2
L1:
t4 = 2
x = t4
L2:
```

---

# Task 11: While Loops (`WhileNode`)

### The Concept: A Loop is an `if` that Jumps Back to Top!
1. `L_start:` (Loop top bookmark)
2. Condition test $\rightarrow$ if true `goto L_body`, if false `goto L_end`
3. `L_body:` $\rightarrow$ run body statements
4. `goto L_start` $\rightarrow$ jump back to top!
5. `L_end:` $\rightarrow$ loop exit.

### Code & Visual Breakdown
```cpp
string generate_code(...) const override {
    string label_start = "L" + to_string(label_count++); // "L6"
    string label_body  = "L" + to_string(label_count++); // "L7"
    string label_end   = "L" + to_string(label_count++); // "L8"

    outcode << label_start << ":" << endl;
    string cond_val = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
    outcode << "if " << cond_val << " goto " << label_body << endl;
    outcode << "goto " << label_end << endl;

    outcode << label_body << ":" << endl;
    if (body) body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
    outcode << "goto " << label_start << endl; // Jump back to top!

    outcode << label_end << ":" << endl;
    return "";
}
```

### Live Trace for `while (c > 0) { c--; }`:
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

### The Concept: The 4 Pieces of a For Loop
`for (init; condition; update) body`
1. `init` runs **once** at the beginning.
2. `L_start:` bookmark.
3. `condition` is tested $\rightarrow$ true `goto L_body`, false `goto L_end`.
4. `L_body:` executes the `body`.
5. `update` runs at the end of each round.
6. `goto L_start` jumps back to condition check.
7. `L_end:` loop exit.

### Code & Visual Breakdown
```cpp
string generate_code(...) const override {
    // 1. Run initialization once
    if (init) init->generate_code(outcode, symbol_to_temp, temp_count, label_count);

    string label_start = "L" + to_string(label_count++); // "L0"
    string label_body  = "L" + to_string(label_count++); // "L1"
    string label_end   = "L" + to_string(label_count++); // "L2"

    // 2. Loop Header
    outcode << label_start << ":" << endl;
    if (condition) {
        string cond_val = condition->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "if " << cond_val << " goto " << label_body << endl;
        outcode << "goto " << label_end << endl;
    }

    // 3. Body
    outcode << label_body << ":" << endl;
    if (body) body->generate_code(outcode, symbol_to_temp, temp_count, label_count);

    // 4. Update Step & Loop Back
    if (update) update->generate_code(outcode, symbol_to_temp, temp_count, label_count);
    outcode << "goto " << label_start << endl;

    // 5. Exit
    outcode << label_end << ":" << endl;
    return "";
}
```

### Live Trace for `for (i = 0; i < 10; i++) { a = c; }`:
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
a = t15
t20 = 1
t21 = i + t20
i = t21
goto L0
L2:
```

---

# Task 13: Return Statements (`ReturnNode`)

### The Concept
- If returning a value: calculates `a + b` into `t2`, writes `return t2`.
- If returning void: writes `return`.

### Code & Visual Breakdown
```cpp
string generate_code(...) const override {
    if (expr) {
        string ret_val = expr->generate_code(outcode, symbol_to_temp, temp_count, label_count);
        outcode << "return " << ret_val << endl;
    } else {
        outcode << "return" << endl;
    }
    return "";
}
```

---

# Task 14: Variable Declarations (`DeclNode`)

### The Concept
In basic Three-Address Code, declarations do not generate CPU math instructions. They output clean **documentation comments** in `code.txt` to clearly show which variables and array sizes exist!

### Code & Visual Breakdown
```cpp
string generate_code(...) const override {
    for (const auto& var : vars) {
        if (var.second > 0) {
            outcode << "// Declaration: " << type << " " << var.first << "[" << var.second << "]" << endl;
        } else {
            outcode << "// Declaration: " << type << " " << var.first << endl;
        }
    }
    return "";
}
```

### Live Trace for `int a, b, f[10];`:
```text
// Declaration: int a
// Declaration: int b
// Declaration: int f[10]
```

---

# Task 15: Function Calls (`FuncCallNode`)

### The Concept
1. Evaluate all arguments first and collect their registers into a shopping bag (`arg_temps`).
2. Pass each parameter using `param tX`.
3. Call function and catch return value: `t_result = call func_name, arg_count`.

### Code & Visual Breakdown
```cpp
string generate_code(...) const override {
    // 1. Calculate all arguments first (Shopping Bag)
    vector<string> arg_temps;
    for (auto arg : arguments) {
        if (arg) {
            string arg_temp = arg->generate_code(outcode, symbol_to_temp, temp_count, label_count);
            arg_temps.push_back(arg_temp);
        }
    }

    // 2. Pass parameters
    for (const auto& at : arg_temps) {
        outcode << "param " << at << endl;
    }

    // 3. Make call and catch return value
    string temp = "t" + to_string(temp_count++);
    outcode << temp << " = call " << func_name << ", " << arguments.size() << endl;
    return temp;
}
```

### Live Trace for `c = calculate(a + 1, 50);`:
```text
t0 = a
t1 = 1
t2 = t0 + t1
t3 = 50
param t2
param t3
t4 = call calculate, 2
c = t4
```

---

# Task 16: Function Definitions & Scope Clearing (`FuncDeclNode`)

### The Concept
Represents a complete function definition.
- **CRITICAL STEP:** Calls `symbol_to_temp.clear()` to wipe the register notebook clean so variables from previous functions don't leak in!
- Prints the `// Function: ...` header comment.
- Runs `body->generate_code(...)` (which is where parameters `a` and `b` generate their TAC when used!).

### Code & Visual Breakdown
```cpp
string generate_code(...) const override {
    // 1. Clear the Notebook for new function scope!
    symbol_to_temp.clear();

    // 2. Print Function Header Comment
    outcode << "// Function: " << return_type << " " << name << "(";
    for (size_t i = 0; i < params.size(); i++) {
        outcode << params[i].first << " " << params[i].second;
        if (i + 1 < params.size()) outcode << ", ";
    }
    outcode << ")" << endl;

    // 3. Generate Body (Where parameters generate TAC when used!)
    if (body) {
        body->generate_code(outcode, symbol_to_temp, temp_count, label_count);
    }
    outcode << endl;
    return "";
}
```

### Live Trace for `int add(int a, float b) { return a + b; }`:
```text
// Function: int add(int a, float b)
t0 = a
t1 = b
t2 = t0 + t1
return t2

```

---

# Task 17: Two-Pass Driver & Error Handling (`main`)

### Code & Visual Breakdown ([`22201161.y` lines 1344–1378](file:///e:/CSE420/LAB4/22201161/22201161.y#L1344-L1378))
```cpp
int main(int argc, char *argv[]) {
    // PASS 1: Flex & Bison parse input, build AST in memory, count errors
    symtbl->enter_scope(outlog);
    yyparse();

    // PASS 2: ONLY generate TAC if there were ZERO errors!
    if (errors == 0 && ast_root) {
        ThreeAddrCodeGenerator tacGen(ast_root, outcode);
        tacGen.generate(); // Walks AST and emits clean TAC to code.txt
    } else {
        outcode << "// Three-Address Code generation skipped due to errors" << endl;
    }
}
```

---

# 20. Top 15 Master Viva Questions & Answers

1. **What is Three-Address Code?**
   > An intermediate language where every instruction has at most 3 operand addresses (at most 2 inputs, 1 output).
2. **Why use an AST instead of emitting code during parsing?**
   > Decouples syntax analysis from code generation, preserves operator precedence naturally, handles forward jump labels easily, and prevents generating partial code if semantic errors exist.
3. **Why did you multiply array indices by 4 or 8?**
   > Computer memory is byte-addressed. An `int` is 4 bytes and a `float`/`double` is 8 bytes. Accessing `a[i]` requires computing the byte offset: $i \times \text{sizeof(type)}$.
4. **Why does `find(name) != end()` mean FOUND in C++?**
   > In `std::map`, `.end()` is an invalid sentinel representing "NOT FOUND". If a key exists, `find()` stops before `.end()`, so `find() != end()` is true.
5. **What is `symbol_to_temp`?**
   > A local register cache within a function that remembers which temporary register holds a variable, avoiding redundant load instructions.
6. **Why is `symbol_to_temp.clear()` called in `FuncDeclNode`?**
   > Registers and local variable mappings belong only to the current function scope and must not leak into subsequent functions.
7. **How do function calls work in TAC?**
   > Arguments are evaluated into temporaries, emitted sequentially using `param tX`, and then invoked via `tY = call func, count`.
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
