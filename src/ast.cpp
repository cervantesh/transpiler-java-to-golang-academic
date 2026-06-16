#include "ast.hpp"

#include <utility>

namespace jtg {

TypeName::TypeName() : javaName("void"), goName(""), isVoid(true) {}

TypeName::TypeName(std::string javaName, std::string goName, bool isVoid)
    : javaName(std::move(javaName)), goName(std::move(goName)), isVoid(isVoid) {}

TypeName TypeName::Int() {
    return TypeName("int", "int");
}

TypeName TypeName::Double() {
    return TypeName("double", "float64");
}

TypeName TypeName::Boolean() {
    return TypeName("boolean", "bool");
}

TypeName TypeName::String() {
    return TypeName("String", "string");
}

TypeName TypeName::StringArray() {
    return TypeName("String[]", "[]string");
}

TypeName TypeName::Void() {
    return TypeName("void", "", true);
}

Param::Param(TypeName type, std::string name)
    : type(std::move(type)), name(std::move(name)) {}

IntLiteralExpr::IntLiteralExpr(std::string value) : value(std::move(value)) {}

DoubleLiteralExpr::DoubleLiteralExpr(std::string value) : value(std::move(value)) {}

StringLiteralExpr::StringLiteralExpr(std::string value) : value(std::move(value)) {}

BoolLiteralExpr::BoolLiteralExpr(bool value) : value(value) {}

IdentifierExpr::IdentifierExpr(std::string name) : name(std::move(name)) {}

CallExpr::CallExpr(std::string callee, std::vector<std::unique_ptr<Expr>> args)
    : callee(std::move(callee)), args(std::move(args)) {}

ParenthesizedExpr::ParenthesizedExpr(std::unique_ptr<Expr> expr)
    : expr(std::move(expr)) {}

UnaryExpr::UnaryExpr(std::string op, std::unique_ptr<Expr> expr)
    : op(std::move(op)), expr(std::move(expr)) {}

BinaryExpr::BinaryExpr(std::string op, std::unique_ptr<Expr> left, std::unique_ptr<Expr> right)
    : op(std::move(op)), left(std::move(left)), right(std::move(right)) {}

bool Stmt::usesFmt() const {
    return false;
}

Block::Block(std::vector<std::unique_ptr<Stmt>> statements)
    : statements(std::move(statements)) {}

bool Block::usesFmt() const {
    for (const auto& statement : statements) {
        if (statement->usesFmt()) {
            return true;
        }
    }
    return false;
}

VarDecl::VarDecl(TypeName type, std::string name, std::unique_ptr<Expr> initializer)
    : type(std::move(type)), name(std::move(name)), initializer(std::move(initializer)) {}

AssignStmt::AssignStmt(std::string name, std::unique_ptr<Expr> value)
    : name(std::move(name)), value(std::move(value)) {}

ExprStmt::ExprStmt(std::unique_ptr<Expr> expr)
    : expr(std::move(expr)) {}

PrintStmt::PrintStmt(std::unique_ptr<Expr> value)
    : value(std::move(value)) {}

bool PrintStmt::usesFmt() const {
    return true;
}

ReturnStmt::ReturnStmt(std::unique_ptr<Expr> value)
    : value(std::move(value)) {}

IfStmt::IfStmt(std::unique_ptr<Expr> condition, std::unique_ptr<Block> thenBlock, std::unique_ptr<Block> elseBlock)
    : condition(std::move(condition)), thenBlock(std::move(thenBlock)), elseBlock(std::move(elseBlock)) {}

bool IfStmt::usesFmt() const {
    return thenBlock->usesFmt() || (elseBlock && elseBlock->usesFmt());
}

WhileStmt::WhileStmt(std::unique_ptr<Expr> condition, std::unique_ptr<Block> body)
    : condition(std::move(condition)), body(std::move(body)) {}

bool WhileStmt::usesFmt() const {
    return body->usesFmt();
}

MethodDecl::MethodDecl(bool isPublic, bool isStatic, TypeName returnType, std::string name, std::vector<Param> params, std::unique_ptr<Block> body)
    : isPublic(isPublic),
      isStatic(isStatic),
      returnType(std::move(returnType)),
      name(std::move(name)),
      params(std::move(params)),
      body(std::move(body)) {}

bool MethodDecl::usesFmt() const {
    return body->usesFmt();
}

Program::Program(std::string className, std::vector<std::unique_ptr<MethodDecl>> methods)
    : className(std::move(className)), methods(std::move(methods)) {}

bool Program::usesFmt() const {
    for (const auto& method : methods) {
        if (method->usesFmt()) {
            return true;
        }
    }
    return false;
}

} // namespace jtg
