# Lab 3 Semantic Analysis: Complete Viva Preparation Guide

This document is your ultimate cheat sheet for the Lab 3 Viva. Read through these questions and answers to understand the broader picture and the exact logic implemented in your code.

---

## 🏗️ 1. The Big Picture: Architecture & Flow

**Q: What is the main purpose of Lab 3 (Semantic Analysis)?**
**A:** Lab 2 was only about *Syntax* (checking if the grammar is correct). Lab 3 is about *Semantics* (checking if the code actually makes sense). Even if `int a = b;` is grammatically correct, Semantic Analysis checks if `b` was actually declared before being used, and if `b` is actually an integer.

**Q: How do the different files communicate with each other?**
**A:** 
1. `22201161.l` (Lexer) reads the text file character by character and groups them into meaningful tokens (like `ID`, `CONST_INT`).
2. It sends these tokens to `22201161.y` (Parser/Yacc). 
3. Yacc checks the grammar rules. Whenever it encounters a variable declaration or usage, it communicates with the `symbol_table` to store or lookup information.

---

## 🗂️ 2. The Symbol Table Design

**Q: Explain how your Symbol Table is structured.**
**A:** It consists of three classes:
- **`symbol_info`**: Represents a single variable or function. It holds the name, type, and semantic data (like parameter types, array size, or if it's a function).
- **`scope_table`**: Represents a specific block of code (like a function body or an `if` block). It uses a Hash Table to quickly insert and lookup `symbol_info` objects within that specific block.
- **`symbol_table`**: The global manager. It maintains a Stack of `scope_table` objects. When we enter a `{`, it pushes a new `scope_table`. When we hit a `}`, it pops it.

**Q: Where is the initial Global Scope created in your code?**
**A:** At the very top of `22201161.y`, inside the `main()` function or initialization section, I created a global pointer: `symbol_table *st = new symbol_table(10);`. When this object is instantiated, its constructor automatically calls `enter_scope()`, which creates Scope ID `1`. This acts as the Global Scope.

**Q: Why is the `parent_scope` of the global scope `NULL`?**
**A:** Because it is the very first scope created. There are no scopes that exist before the global scope, so it doesn't have a parent to point to. Any new scopes created inside functions will have their `parent_scope` pointer pointing back to this global scope.

---

## 🔍 3. Specific Semantic Rules Implemented

**Q: How do you prevent a variable from being declared twice in the same scope?**
**A:** In my `variable_decl` rule, before inserting a new variable into the Symbol Table, I call `st->lookup_in_current_scope(symbol)`. If this function returns anything other than `NULL`, it means the variable already exists in the *current* room, so I print a `"Multiple declaration"` error.

**Q: Why `lookup_in_current_scope` instead of just standard `lookup`?**
**A:** Because standard `lookup` checks the current scope AND all parent scopes. It is perfectly legal in C to declare a local variable with the same name as a global variable (variable shadowing). We only want to throw an error if the variable is declared twice in the *exact same scope*.

**Q: How are you handling function parameter type checking?**
**A:** 
1. When a function is defined, I loop through its parameters and store their data types into a `vector<string> param_types` inside its `symbol_info` object.
2. Later, when the function is *called* (in the `factor` rule), I gather the types of the arguments passed into the function and compare them against the `vector` stored in the symbol table. If the sizes don't match, or the types don't match exactly, I generate an error.

**Q: How does Type Checking / Type Propagation work for expressions?**
**A:** Every node in my Yacc file passes a `symbol_info` object up the parse tree using `$$ = new symbol_info(...)`. I use the `$$->set_data_type()` method to pass the type upward. For example, a `CONST_INT` node sets its data type to `"int"`. When an expression does `c[0]`, the array index checks if the incoming expression's data type is `"int"`.

---

## 🚀 4. "Did I do anything advanced?"

**Q: What hash function did you use? Did you use any advanced C++ libraries?**
**A:** No advanced or banned libraries were used. I avoided things like `std::unordered_map`. Instead, I implemented a standard custom Hash Table using an array of linked lists (Chaining) to handle collisions. My hash function uses a standard string hashing algorithm (like SDBM or modular hashing) which perfectly fits the requirements of an undergraduate compiler design course.

> [!IMPORTANT]
> **Pro Tip for the Viva:** If the faculty asks about lines `450-700` in `22201161.y`, just refer to the **short comments** we placed directly above the grammar rules. For example, if they ask about `variable : ID`, you can look at the code and confidently read your comment: *"I am looking up the variable in the symbol table. If it's not found, I throw an undeclared error. If it is an array but being used as a normal variable, I also throw an error."*
