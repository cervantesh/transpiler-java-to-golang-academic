%option noyywrap
%option nounput
%option noinput
%option yylineno

%{
/*
 * Flex scanner for the academic Java subset.
 *
 * The scanner recognizes only the tokens that the Bison grammar supports.
 * It also records line/column positions so syntax errors can point to the
 * original Java source location.
 */
#include "parser.hpp"

#include <cstdlib>
#include <cstring>

static int currentColumn = 1;

/* Bison owns semantic token values, so token text is copied with malloc and
 * later released in parser.y after the AST node takes the string value.
 */
static char* duplicateText(const char* text) {
    const size_t length = std::strlen(text) + 1;
    char* copy = static_cast<char*>(std::malloc(length));
    if (copy != nullptr) {
        std::memcpy(copy, text, length);
    }
    return copy;
}

#define YY_USER_ACTION \
    yylloc.first_line = yylloc.last_line = yylineno; \
    yylloc.first_column = currentColumn; \
    yylloc.last_column = currentColumn + static_cast<int>(yyleng) - 1; \
    currentColumn += static_cast<int>(yyleng);
%}

identifier      [A-Za-z_][A-Za-z0-9_]*
integer         [0-9]+
double          [0-9]+\.[0-9]+
string_literal  \"([^\\\"\n]|\\.)*\"

%%

    /* Whitespace and comments are ignored, but newlines still reset column state. */
[ \t\r]+                    ;
\n                          { currentColumn = 1; }
"//"[^\n]*                  ;
"/*"([^*]|\*+[^*/])*\*+"/"  {
                                for (int i = 0; i < yyleng; ++i) {
                                    if (yytext[i] == '\n') {
                                        currentColumn = 1;
                                    }
                                }
                            }

    /* Java keywords supported by the academic grammar. */
"public"                    return PUBLIC;
"static"                    return STATIC;
"class"                     return CLASS;
"void"                      return VOID;
"int"                       return INT;
"double"                    return DOUBLE;
"boolean"                   return BOOLEAN;
"String"                    return STRING;
"if"                        return IF;
"else"                      return ELSE;
"while"                     return WHILE;
"return"                    return RETURN;
"true"                      return TRUE;
"false"                     return FALSE;
"System.out.println"        return PRINTLN;

    /* Multi-character operators must be matched before their one-character parts. */
"&&"                        return AND;
"||"                        return OR;
"=="                        return EQ;
"!="                        return NE;
"<="                        return LE;
">="                        return GE;

{double}                    { yylval.text = duplicateText(yytext); return DOUBLE_LITERAL; }
{integer}                   { yylval.text = duplicateText(yytext); return INT_LITERAL; }
{string_literal}            { yylval.text = duplicateText(yytext); return STRING_LITERAL; }
{identifier}                { yylval.text = duplicateText(yytext); return IDENTIFIER; }

    /* Punctuation and single-character operators are returned as literal tokens. */
"{"                         return '{';
"}"                         return '}';
"("                         return '(';
")"                         return ')';
"["                         return '[';
"]"                         return ']';
";"                         return ';';
","                         return ',';
"="                         return '=';
"+"                         return '+';
"-"                         return '-';
"*"                         return '*';
"/"                         return '/';
"<"                         return '<';
">"                         return '>';
"!"                         return '!';

.                           {
                                std::fprintf(stderr, "lex error at line %d, column %d: unexpected character '%s'\n",
                                             yylloc.first_line, yylloc.first_column, yytext);
                                return yytext[0];
                            }

%%
