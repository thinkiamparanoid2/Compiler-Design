%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

symbol_table *st = new symbol_table(10);

int lines = 1;

ofstream outlog;
ofstream errorlog;
int error_count = 0;

string current_type;
vector<string> current_param_types;
vector<string> current_param_names;
vector<pair<string, int>> decl_list;
bool in_function = false;

void yyerror(char *s)
{
	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;
	errorlog<<"At line "<<lines<<" "<<s<<endl<<endl;
	error_count++;
}

void print_error(string msg)
{
    errorlog << "At line no: " << lines << " " << msg << endl << endl;
    error_count++;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;
		
		st->print_all_scopes(outlog);
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->getname()+"\n"+$2->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"program");
	}
	;

unit : variable_decl
	 {
		outlog<<"At line no: "<<lines<<" unit : variable_decl "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
		
		$$ = new symbol_info($1->getname(),"unit");
	 }
     ;

// function definition and storing parameters to symbol table
// checking if function is already defined, and also checking if any parameter name is repeated
func_definition : type_specifier ID LPAREN param_list RPAREN
		{
			symbol_info temp($2->getname(), "ID");
			if (st->lookup_in_current_scope(&temp) != NULL)
			{
				print_error("Multiple declaration of function " + $2->getname());
			}
			else
			{
				symbol_info *func_sym = new symbol_info($2->getname(), "ID");
				func_sym->set_symbol_kind("Function Definition");
				func_sym->set_data_type($1->getname());
				for (int i = 0; i < current_param_types.size(); i++)
				{
					for (int j = 0; j < i; j++) {
						if (current_param_names[i] != "" && current_param_names[i] == current_param_names[j]) {
							print_error("Multiple declaration of variable " + current_param_names[i] + " in parameter of " + $2->getname());
							break;
						}
					}
					func_sym->add_param(current_param_types[i], current_param_names[i]);
				}
				st->insert(func_sym);
			}
			in_function = true;
		}
		compound_statement
		{	
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"("+$4->getname()+")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"("+$4->getname()+")\n"+$7->getname(),"func_def");	
		}
		| type_specifier ID LPAREN RPAREN
		{
			symbol_info temp($2->getname(), "ID");
			if (st->lookup_in_current_scope(&temp) != NULL)
			{
				print_error("Multiple declaration of function " + $2->getname());
			}
			else
			{
				symbol_info *func_sym = new symbol_info($2->getname(), "ID");
				func_sym->set_symbol_kind("Function Definition");
				func_sym->set_data_type($1->getname());
				st->insert(func_sym);
			}
			in_function = true;
			current_param_types.clear();
			current_param_names.clear();
		}
		compound_statement
		{
			
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<"()\n"<<$6->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+"()\n"+$6->getname(),"func_def");	
		}
 		;

// parameter list buffering
param_list : param_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<" "<<$4->getname()<<endl<<endl;
					
			$$ = new symbol_info($1->getname()+","+$3->getname()+" "+$4->getname(),"param_list");
			
			current_param_types.push_back($3->getname());
			current_param_names.push_back($4->getname());
		}
		| param_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : param_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+","+$3->getname(),"param_list");
			
			current_param_types.push_back($3->getname());
			current_param_names.push_back("");
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname(),"param_list");
			
			current_param_types.clear();
			current_param_names.clear();
			current_param_types.push_back($1->getname());
			current_param_names.push_back($2->getname());
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" param_list : type_specifier "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"param_list");
			
			current_param_types.clear();
			current_param_names.clear();
			current_param_types.push_back($1->getname());
			current_param_names.push_back("");
		}
 		;

// scope creation and destruction for code blocks
compound_statement : LCURL
			{
				if (in_function)
				{
					st->enter_scope();
					outlog<<"New ScopeTable with ID "<<st->get_current_scope_id()<<" created"<<endl<<endl;
					for (int i = 0; i < current_param_types.size(); i++)
					{
						symbol_info *param = new symbol_info(current_param_names[i], "ID");
						param->set_symbol_kind("Variable");
						param->set_data_type(current_param_types[i]);
						st->insert(param);
					}
					in_function = false;
				}
				else
				{
					st->enter_scope();
					outlog<<"New ScopeTable with ID "<<st->get_current_scope_id()<<" created"<<endl<<endl;
				}
			}
			statements RCURL
			{ 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->getname()+"\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n"+$3->getname()+"\n}","comp_stmnt");
				
				st->print_all_scopes(outlog);
				outlog<<"Scopetable with ID "<<st->get_current_scope_id()<<" removed"<<endl<<endl;
				st->exit_scope();
 		    }
 		    | LCURL
 		    {
 		    	if (in_function)
				{
					st->enter_scope();
					outlog<<"New ScopeTable with ID "<<st->get_current_scope_id()<<" created"<<endl<<endl;
					for (int i = 0; i < current_param_types.size(); i++)
					{
						symbol_info *param = new symbol_info(current_param_names[i], "ID");
						param->set_symbol_kind("Variable");
						param->set_data_type(current_param_types[i]);
						st->insert(param);
					}
					in_function = false;
				}
				else
				{
					st->enter_scope();
					outlog<<"New ScopeTable with ID "<<st->get_current_scope_id()<<" created"<<endl<<endl;
				}
 		    }
 		    RCURL
 		    { 
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;
				
				$$ = new symbol_info("{\n}","comp_stmnt");
				
				st->print_all_scopes(outlog);
				outlog<<"Scopetable with ID "<<st->get_current_scope_id()<<" removed"<<endl<<endl;
				st->exit_scope();
 		    }
 		    ;
 		    
// inserting buffered variables into symbol table
variable_decl : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" variable_decl : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->getname()<<" "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+" "+$2->getname()+";","var_dec");
			
			// if variable type is void, throw error. else loop through variables and check if already declared, if not then insert to st
			if (current_type == "void")
			{
				print_error("variable type can not be void");
			}
			else
			{
				for (int i = 0; i < decl_list.size(); i++)
				{
					symbol_info temp(decl_list[i].first, "ID");
					if (st->lookup_in_current_scope(&temp) != NULL)
					{
						print_error("Multiple declaration of variable " + decl_list[i].first);
					}
					else
					{
						symbol_info *var = new symbol_info(decl_list[i].first, "ID");
						if (decl_list[i].second == -1)
						{
							var->set_symbol_kind("Variable");
							var->set_data_type(current_type);
						}
						else
						{
							var->set_symbol_kind("Array");
							var->set_data_type(current_type);
							var->set_array_size(decl_list[i].second);
						}
						st->insert(var);
					}
				}
			}
			decl_list.clear();
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;
			
			$$ = new symbol_info("int","type");
			current_type = "int";
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;
			
			$$ = new symbol_info("float","type");
			current_type = "float";
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;
			
			$$ = new symbol_info("void","type");
			current_type = "void";
	    }
		| CHAR
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : CHAR "<<endl<<endl;
			outlog<<"char"<<endl<<endl;
			
			$$ = new symbol_info("char","type");
			current_type = "char";
	    }
 		;

// buffering variable and array declarations
declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<endl<<endl;

			$$ = new symbol_info($1->getname()+","+$3->getname(),"decl_list");
			decl_list.push_back(make_pair($3->getname(), -1));
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	outlog<<$1->getname()+","<<$3->getname()<<"["<<$5->getname()<<"]"<<endl<<endl;

			$$ = new symbol_info($1->getname()+","+$3->getname()+"["+$5->getname()+"]","decl_list");
			decl_list.push_back(make_pair($3->getname(), stoi($5->getname())));
 		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;

			$$ = new symbol_info($1->getname(),"decl_list");
			decl_list.clear();
			decl_list.push_back(make_pair($1->getname(), -1));
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;

			$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","decl_list");
			decl_list.clear();
			decl_list.push_back(make_pair($1->getname(), stoi($3->getname())));
 		  }
 		  ;
 		  

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->getname()<<"\n"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+"\n"+$2->getname(),"stmnts");
	   }
	   ;
	   
statement : variable_decl
	  {
	    	outlog<<"At line no: "<<lines<<" statement : variable_decl "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | func_definition
	  {
	  		outlog<<"At line no: "<<lines<<" statement : func_definition "<<endl<<endl;
            outlog<<$1->getname()<<endl<<endl;

            $$ = new symbol_info($1->getname(),"stmnt");
	  		
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->getname()<<$4->getname()<<$5->getname()<<")\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("for("+$3->getname()+$4->getname()+$5->getname()+")\n"+$7->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->getname()<<")\n"<<$5->getname()<<"\nelse\n"<<$7->getname()<<endl<<endl;
			
			$$ = new symbol_info("if("+$3->getname()+")\n"+$5->getname()+"\nelse\n"+$7->getname(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->getname()<<")\n"<<$5->getname()<<endl<<endl;
			
			$$ = new symbol_info("while("+$3->getname()+")\n"+$5->getname(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->getname()<<");"<<endl<<endl; 
			
			symbol_info *var = st->lookup($3);
			if (var == NULL) {
				print_error("Undeclared variable " + $3->getname());
			}

			$$ = new symbol_info("printf("+$3->getname()+");","stmnt");
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->getname()<<";"<<endl<<endl;
			
			$$ = new symbol_info("return "+$2->getname()+";","stmnt");
	  }
	  ;
	  
expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;
				
				$$ = new symbol_info(";","expr_stmt");
	        }			
			| expression SEMICOLON 
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->getname()<<";"<<endl<<endl;
				
				$$ = new symbol_info($1->getname()+";","expr_stmt");
	        }
			;
	  
variable : ID 	
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		// looking up variable in st. if not found, undeclared error. if it's an array but used like a normal variable, throw error.
		symbol_info *var = st->lookup($1);
		if (var == NULL) {
			print_error("Undeclared variable " + $1->getname());
		} else if (var->get_symbol_kind() == "Array") {
			print_error("variable is of array type : " + $1->getname());
		}

		$$ = new symbol_info($1->getname(),"varbl");
		if (var != NULL) $$->set_data_type(var->get_data_type());
	 }	
	 | ID LTHIRD expression RTHIRD 
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->getname()<<"["<<$3->getname()<<"]"<<endl<<endl;
		
		// looking up array. checking if index is integer
		symbol_info *var = st->lookup($1);
		if (var == NULL) {
			print_error("Undeclared variable " + $1->getname());
		} else if (var->get_symbol_kind() != "Array") {
			print_error("variable is not of array type : " + $1->getname());
		} else if ($3->get_data_type() != "int") {
			print_error("array index is not of integer type : " + $1->getname());
		}
		
		$$ = new symbol_info($1->getname()+"["+$3->getname()+"]","varbl");
		if (var != NULL) $$->set_data_type(var->get_data_type());
	 }
	 ;
	 
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"expr");
			$$->set_data_type($1->get_data_type());
	   }
	   | variable ASSIGNOP logic_expression 	
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->getname()<<"="<<$3->getname()<<endl<<endl;

			$$ = new symbol_info($1->getname()+"="+$3->getname(),"expr");
			
			if ($3->get_data_type() == "void") {
				print_error("Void function used in expression");
			} 
			else if ($1->get_data_type() == "int" && $3->get_data_type() == "float") {
				print_error("Type Mismatch: Warning - assigning float to integer variable");
			} 
			else if ($1->get_data_type() != "" && $3->get_data_type() != "" && $1->get_data_type() != $3->get_data_type() && !($1->get_data_type() == "float" && $3->get_data_type() == "int")) {
				print_error("Type Mismatch: operands are not consistent with each other");
			}
			$$->set_data_type($1->get_data_type());
	   }
	   ;
			
logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"lgc_expr");
			$$->set_data_type($1->get_data_type());
	     }	
		 | rel_expression LOGICOP rel_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"lgc_expr");
			$$->set_data_type("int");
	     }	
		 ;
			
rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"rel_expr");
			$$->set_data_type($1->get_data_type());
	    }
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"rel_expr");
			$$->set_data_type("int");
	    }
		;
				
simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"simp_expr");
			$$->set_data_type($1->get_data_type());
	      }
		  | simple_expression ADDOP term 
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"simp_expr");
			
			if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
				print_error("Void function used in expression");
			}
			if ($1->get_data_type() == "float" || $3->get_data_type() == "float") {
				$$->set_data_type("float");
			} else {
				$$->set_data_type("int");
			}
	      }
		  ;
					
term :	unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"term");
			$$->set_data_type($1->get_data_type());
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<$3->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname()+$3->getname(),"term");
			
			if ($2->getname() == "%") {
				if ($1->get_data_type() != "int" || $3->get_data_type() != "int") {
					print_error("Non-Integer operand on modulus operator");
				}
				if ($3->getname() == "0") {
					print_error("Modulus by Zero");
				}
			} else if ($2->getname() == "/") {
				if ($3->getname() == "0") {
					print_error("Warning: division by zero");
				}
			}
			if ($1->get_data_type() == "void" || $3->get_data_type() == "void") {
				print_error("Void function used in expression");
			}
			if ($1->get_data_type() == "float" || $3->get_data_type() == "float") {
				$$->set_data_type("float");
			} else {
				$$->set_data_type("int");
			}
	 }
     ;

unary_expression : ADDOP unary_expression
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->getname()<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname()+$2->getname(),"un_expr");
			$$->set_data_type($2->get_data_type());
	     }
		 | NOT unary_expression 
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->getname()<<endl<<endl;
			
			$$ = new symbol_info("!"+$2->getname(),"un_expr");
			$$->set_data_type("int");
	     }
		 | factor_info
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor_info "<<endl<<endl;
			outlog<<$1->getname()<<endl<<endl;
			
			$$ = new symbol_info($1->getname(),"un_expr");
			$$->set_data_type($1->get_data_type());
	     }
		 ;
factor_info : factor	{
	    outlog<<"At line no: "<<lines<<" factor_info : factor "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr_info");
		$$->set_data_type($1->get_data_type());
	}	
factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_data_type($1->get_data_type());
	}
	// function call parameter check
	// checking if function exists and if number of arguments matches. then checking if types match
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->getname()<<"("<<$3->getname()<<")"<<endl<<endl;

		$$ = new symbol_info($1->getname()+"("+$3->getname()+")","fctr");

		symbol_info *func = st->lookup($1);
		if (func == NULL)
		{
			print_error("Undeclared function: " + $1->getname());
		}
		else if (func->get_symbol_kind() != "Function Definition")
		{
			print_error("Function call made with non-function type identifier: " + $1->getname());
		}
		else
		{
			$$->set_data_type(func->get_data_type()); // Propagate return type
			
			vector<string> ptypes = func->get_param_types();
			vector<string> atypes = $3->get_param_types();
			if (ptypes.size() != atypes.size())
			{
				print_error("Inconsistencies in number of arguments in function call: " + $1->getname());
			}
			else
			{
				for (int i = 0; i < ptypes.size(); i++)
				{
					if (ptypes[i] != atypes[i])
					{
						// E.g., if passing float to int or int to float or void... wait, type conversion:
						// Does type mismatch trigger strictly if not equal?
						// In input1.c: func(2.5, 3.5) -> argument 1 type mismatch, argument 2 type mismatch.
						// So strict equality!
						print_error("argument " + to_string(i+1) + " type mismatch in function call: " + $1->getname());
					}
				}
			}
		}
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->getname()<<")"<<endl<<endl;
		
		$$ = new symbol_info("("+$2->getname()+")","fctr");
		$$->set_data_type($2->get_data_type());
	}
	| CONST_INT 
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_data_type("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->getname()<<endl<<endl;
			
		$$ = new symbol_info($1->getname(),"fctr");
		$$->set_data_type("float");
	}
	| variable INCOP 
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->getname()<<"++"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"++","fctr");
		$$->set_data_type($1->get_data_type());
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->getname()<<"--"<<endl<<endl;
			
		$$ = new symbol_info($1->getname()+"--","fctr");
		$$->set_data_type($1->get_data_type());
	}
	;
	
argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->getname()<<endl<<endl;
						
					$$ = new symbol_info($1->getname(),"arg_list");
					// passing parameter types up so we can check them in function call
					for (int i=0; i<$1->get_param_count(); i++) {
						$$->add_param($1->get_param_types()[i], "");
					}
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;
						
					$$ = new symbol_info("","arg_list");
			  }
			  ;
	
arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<","<<$3->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname()+","+$3->getname(),"arg");
				// passing parameter types up so we can check them in function call
				for (int i=0; i<$1->get_param_count(); i++) {
					$$->add_param($1->get_param_types()[i], "");
				}
				$$->add_param($3->get_data_type(), "");
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->getname()<<endl<<endl;
						
				$$ = new symbol_info($1->getname(),"arg");
				// passing parameter types up so we can check them in function call
				$$->add_param($1->get_data_type(), "");
		  }
	      ;
 

%%

int main(int argc, char *argv[])
{
	if(argc != 2) 
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("log.txt", ios::trunc);
	errorlog.open("error.txt", ios::trunc);
	
	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}

	outlog<<"New ScopeTable with ID 1 created"<<endl<<endl;

	yyparse();
	
	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog<<"Total errors: "<<error_count<<endl;
	
	errorlog<<endl<<"Total errors: "<<error_count<<endl;
	
	outlog.close();
	errorlog.close();
	
	fclose(yyin);
	
	return 0;
}