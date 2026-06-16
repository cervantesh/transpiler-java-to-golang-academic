%{
#include "ast.hpp"
#include "parser_driver.hpp"

#include <cstdio>
#include <cstdlib>
#include <memory>
#include <sstream>
#include <stdexcept>
#include <string>
#include <utility>
#include <vector>

extern int yylex(void);
extern FILE* yyin;
extern int yyparse(void);

void yyerror(const char* message);

namespace {
std::unique_ptr<jtg::Program> parsedProgram;

std::string takeText(char* value) {
    std::string result(value);
    std::free(value);
    return result;
}

template <typename T>
std::unique_ptr<T> own(T* value) {
    return std::unique_ptr<T>(value);
}
}
%}

%code requires {
    #include "ast.hpp"

    #include <memory>
    #include <vector>

    namespace jtg {
    using ExprList = std::vector<std::unique_ptr<Expr>>;
    using StmtList = std::vector<std::unique_ptr<Stmt>>;
    using MethodList = std::vector<std::unique_ptr<MethodDecl>>;
    using ParamList = std::vector<Param>;
    }
}

%locations
%define parse.error detailed

%union {
    char* text;
    jtg::TypeName* type;
    jtg::Param* param;
    jtg::ParamList* params;
    jtg::Expr* expr;
    jtg::ExprList* exprs;
    jtg::Stmt* stmt;
    jtg::StmtList* stmts;
    jtg::Block* block;
    jtg::MethodDecl* method;
    jtg::MethodList* methods;
}

%token PUBLIC STATIC CLASS VOID INT DOUBLE BOOLEAN STRING IF ELSE WHILE RETURN TRUE FALSE PRINTLN
%token AND OR EQ NE LE GE
%token <text> IDENTIFIER INT_LITERAL DOUBLE_LITERAL STRING_LITERAL

%type <type> type return_type param_type
%type <param> param
%type <params> param_list param_list_opt
%type <expr> expr
%type <exprs> arg_list arg_list_opt
%type <stmt> stmt var_decl assign_stmt print_stmt return_stmt if_stmt while_stmt
%type <stmts> stmt_list
%type <block> block
%type <method> method_decl
%type <methods> method_list

%left OR
%left AND
%left EQ NE
%left '<' '>' LE GE
%left '+' '-'
%left '*' '/'
%right '!'
%right UMINUS

%start program

%%

program
    : PUBLIC CLASS IDENTIFIER '{' method_list '}'
      {
          parsedProgram = std::make_unique<jtg::Program>(takeText($3), std::move(*$5));
          delete $5;
      }
    ;

method_list
    : method_decl
      {
          $$ = new jtg::MethodList();
          $$->push_back(own($1));
      }
    | method_list method_decl
      {
          $1->push_back(own($2));
          $$ = $1;
      }
    ;

method_decl
    : PUBLIC STATIC return_type IDENTIFIER '(' param_list_opt ')' block
      {
          $$ = new jtg::MethodDecl(true, true, *$3, takeText($4), std::move(*$6), own($8));
          delete $3;
          delete $6;
      }
    | STATIC return_type IDENTIFIER '(' param_list_opt ')' block
      {
          $$ = new jtg::MethodDecl(false, true, *$2, takeText($3), std::move(*$5), own($7));
          delete $2;
          delete $5;
      }
    ;

return_type
    : type { $$ = $1; }
    | VOID { $$ = new jtg::TypeName(jtg::TypeName::Void()); }
    ;

type
    : INT { $$ = new jtg::TypeName(jtg::TypeName::Int()); }
    | DOUBLE { $$ = new jtg::TypeName(jtg::TypeName::Double()); }
    | BOOLEAN { $$ = new jtg::TypeName(jtg::TypeName::Boolean()); }
    | STRING { $$ = new jtg::TypeName(jtg::TypeName::String()); }
    ;

param_type
    : type { $$ = $1; }
    | STRING '[' ']' { $$ = new jtg::TypeName(jtg::TypeName::StringArray()); }
    ;

param_list_opt
    : %empty { $$ = new jtg::ParamList(); }
    | param_list { $$ = $1; }
    ;

param_list
    : param
      {
          $$ = new jtg::ParamList();
          $$->push_back(std::move(*$1));
          delete $1;
      }
    | param_list ',' param
      {
          $1->push_back(std::move(*$3));
          delete $3;
          $$ = $1;
      }
    ;

param
    : param_type IDENTIFIER
      {
          $$ = new jtg::Param(*$1, takeText($2));
          delete $1;
      }
    ;

block
    : '{' stmt_list '}'
      {
          $$ = new jtg::Block(std::move(*$2));
          delete $2;
      }
    | '{' '}'
      {
          $$ = new jtg::Block(jtg::StmtList());
      }
    ;

stmt_list
    : stmt
      {
          $$ = new jtg::StmtList();
          $$->push_back(own($1));
      }
    | stmt_list stmt
      {
          $1->push_back(own($2));
          $$ = $1;
      }
    ;

stmt
    : var_decl ';' { $$ = $1; }
    | assign_stmt ';' { $$ = $1; }
    | print_stmt ';' { $$ = $1; }
    | return_stmt ';' { $$ = $1; }
    | if_stmt { $$ = $1; }
    | while_stmt { $$ = $1; }
    ;

var_decl
    : type IDENTIFIER
      {
          $$ = new jtg::VarDecl(*$1, takeText($2), nullptr);
          delete $1;
      }
    | type IDENTIFIER '=' expr
      {
          $$ = new jtg::VarDecl(*$1, takeText($2), own($4));
          delete $1;
      }
    ;

assign_stmt
    : IDENTIFIER '=' expr
      {
          $$ = new jtg::AssignStmt(takeText($1), own($3));
      }
    ;

print_stmt
    : PRINTLN '(' expr ')'
      {
          $$ = new jtg::PrintStmt(own($3));
      }
    ;

return_stmt
    : RETURN
      {
          $$ = new jtg::ReturnStmt(nullptr);
      }
    | RETURN expr
      {
          $$ = new jtg::ReturnStmt(own($2));
      }
    ;

if_stmt
    : IF '(' expr ')' block
      {
          $$ = new jtg::IfStmt(own($3), own($5), nullptr);
      }
    | IF '(' expr ')' block ELSE block
      {
          $$ = new jtg::IfStmt(own($3), own($5), own($7));
      }
    ;

while_stmt
    : WHILE '(' expr ')' block
      {
          $$ = new jtg::WhileStmt(own($3), own($5));
      }
    ;

arg_list_opt
    : %empty { $$ = new jtg::ExprList(); }
    | arg_list { $$ = $1; }
    ;

arg_list
    : expr
      {
          $$ = new jtg::ExprList();
          $$->push_back(own($1));
      }
    | arg_list ',' expr
      {
          $1->push_back(own($3));
          $$ = $1;
      }
    ;

expr
    : INT_LITERAL
      {
          $$ = new jtg::IntLiteralExpr(takeText($1));
      }
    | DOUBLE_LITERAL
      {
          $$ = new jtg::DoubleLiteralExpr(takeText($1));
      }
    | STRING_LITERAL
      {
          $$ = new jtg::StringLiteralExpr(takeText($1));
      }
    | TRUE
      {
          $$ = new jtg::BoolLiteralExpr(true);
      }
    | FALSE
      {
          $$ = new jtg::BoolLiteralExpr(false);
      }
    | IDENTIFIER
      {
          $$ = new jtg::IdentifierExpr(takeText($1));
      }
    | IDENTIFIER '(' arg_list_opt ')'
      {
          $$ = new jtg::CallExpr(takeText($1), std::move(*$3));
          delete $3;
      }
    | '(' expr ')'
      {
          $$ = new jtg::ParenthesizedExpr(own($2));
      }
    | '!' expr
      {
          $$ = new jtg::UnaryExpr("!", own($2));
      }
    | '-' expr %prec UMINUS
      {
          $$ = new jtg::UnaryExpr("-", own($2));
      }
    | expr '+' expr
      {
          $$ = new jtg::BinaryExpr("+", own($1), own($3));
      }
    | expr '-' expr
      {
          $$ = new jtg::BinaryExpr("-", own($1), own($3));
      }
    | expr '*' expr
      {
          $$ = new jtg::BinaryExpr("*", own($1), own($3));
      }
    | expr '/' expr
      {
          $$ = new jtg::BinaryExpr("/", own($1), own($3));
      }
    | expr '<' expr
      {
          $$ = new jtg::BinaryExpr("<", own($1), own($3));
      }
    | expr '>' expr
      {
          $$ = new jtg::BinaryExpr(">", own($1), own($3));
      }
    | expr LE expr
      {
          $$ = new jtg::BinaryExpr("<=", own($1), own($3));
      }
    | expr GE expr
      {
          $$ = new jtg::BinaryExpr(">=", own($1), own($3));
      }
    | expr EQ expr
      {
          $$ = new jtg::BinaryExpr("==", own($1), own($3));
      }
    | expr NE expr
      {
          $$ = new jtg::BinaryExpr("!=", own($1), own($3));
      }
    | expr AND expr
      {
          $$ = new jtg::BinaryExpr("&&", own($1), own($3));
      }
    | expr OR expr
      {
          $$ = new jtg::BinaryExpr("||", own($1), own($3));
      }
    ;

%%

void yyerror(const char* message) {
    std::ostringstream error;
    error << "parse error at line " << yylloc.first_line << ", column " << yylloc.first_column
          << ": " << message;
    throw std::runtime_error(error.str());
}

namespace jtg {

std::unique_ptr<Program> parseJavaFile(const std::string& path) {
    FILE* input = std::fopen(path.c_str(), "rb");
    if (!input) {
        throw std::runtime_error("could not open input file: " + path);
    }

    yyin = input;
    parsedProgram.reset();

    try {
        const int result = yyparse();
        std::fclose(input);

        if (result != 0) {
            throw std::runtime_error("parse failed");
        }

        if (!parsedProgram) {
            throw std::runtime_error("parse completed without producing a program");
        }

        return std::move(parsedProgram);
    } catch (...) {
        std::fclose(input);
        parsedProgram.reset();
        throw;
    }
}

} // namespace jtg
