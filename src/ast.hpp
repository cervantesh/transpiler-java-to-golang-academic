#pragma once

#include <memory>
#include <string>
#include <vector>

namespace jtg {

/* Target-neutral type description for the small Java subset.
 * The parser records both the original Java spelling and the Go output type.
 */
struct TypeName {
    std::string javaName;
    std::string goName;
    bool isVoid;

    TypeName();
    TypeName(std::string javaName, std::string goName, bool isVoid = false);

    static TypeName Int();
    static TypeName Double();
    static TypeName Boolean();
    static TypeName String();
    static TypeName StringArray();
    static TypeName Void();
};

struct Param {
    TypeName type;
    std::string name;

    Param(TypeName type, std::string name);
};

struct Node {
    virtual ~Node() = default;
};

struct Expr : Node {
    ~Expr() override = default;
};

/* Expression nodes are intentionally minimal. They represent only constructs
 * that the generator can emit deterministically as Go source.
 */
struct IntLiteralExpr final : Expr {
    std::string value;
    explicit IntLiteralExpr(std::string value);
};

struct DoubleLiteralExpr final : Expr {
    std::string value;
    explicit DoubleLiteralExpr(std::string value);
};

struct StringLiteralExpr final : Expr {
    std::string value;
    explicit StringLiteralExpr(std::string value);
};

struct BoolLiteralExpr final : Expr {
    bool value;
    explicit BoolLiteralExpr(bool value);
};

struct IdentifierExpr final : Expr {
    std::string name;
    explicit IdentifierExpr(std::string name);
};

struct CallExpr final : Expr {
    std::string callee;
    std::vector<std::unique_ptr<Expr>> args;

    CallExpr(std::string callee, std::vector<std::unique_ptr<Expr>> args);
};

struct ParenthesizedExpr final : Expr {
    std::unique_ptr<Expr> expr;

    explicit ParenthesizedExpr(std::unique_ptr<Expr> expr);
};

struct UnaryExpr final : Expr {
    std::string op;
    std::unique_ptr<Expr> expr;

    UnaryExpr(std::string op, std::unique_ptr<Expr> expr);
};

struct BinaryExpr final : Expr {
    std::string op;
    std::unique_ptr<Expr> left;
    std::unique_ptr<Expr> right;

    BinaryExpr(std::string op, std::unique_ptr<Expr> left, std::unique_ptr<Expr> right);
};

struct Stmt : Node {
    ~Stmt() override = default;
    virtual bool usesFmt() const;
};

/* Blocks and statements know whether they need fmt so the generator can avoid
 * importing fmt when the program does not print anything.
 */
struct Block final : Node {
    std::vector<std::unique_ptr<Stmt>> statements;

    explicit Block(std::vector<std::unique_ptr<Stmt>> statements);
    bool usesFmt() const;
};

struct VarDecl final : Stmt {
    TypeName type;
    std::string name;
    std::unique_ptr<Expr> initializer;

    VarDecl(TypeName type, std::string name, std::unique_ptr<Expr> initializer);
};

struct AssignStmt final : Stmt {
    std::string name;
    std::unique_ptr<Expr> value;

    AssignStmt(std::string name, std::unique_ptr<Expr> value);
};

struct ExprStmt final : Stmt {
    std::unique_ptr<Expr> expr;

    explicit ExprStmt(std::unique_ptr<Expr> expr);
};

struct PrintStmt final : Stmt {
    std::unique_ptr<Expr> value;

    explicit PrintStmt(std::unique_ptr<Expr> value);
    bool usesFmt() const override;
};

struct ReturnStmt final : Stmt {
    std::unique_ptr<Expr> value;

    explicit ReturnStmt(std::unique_ptr<Expr> value);
};

struct IfStmt final : Stmt {
    std::unique_ptr<Expr> condition;
    std::unique_ptr<Block> thenBlock;
    std::unique_ptr<Block> elseBlock;

    IfStmt(std::unique_ptr<Expr> condition, std::unique_ptr<Block> thenBlock, std::unique_ptr<Block> elseBlock);
    bool usesFmt() const override;
};

struct WhileStmt final : Stmt {
    std::unique_ptr<Expr> condition;
    std::unique_ptr<Block> body;

    WhileStmt(std::unique_ptr<Expr> condition, std::unique_ptr<Block> body);
    bool usesFmt() const override;
};

struct MethodDecl final : Node {
    bool isPublic;
    bool isStatic;
    TypeName returnType;
    std::string name;
    std::vector<Param> params;
    std::unique_ptr<Block> body;

    MethodDecl(bool isPublic, bool isStatic, TypeName returnType, std::string name, std::vector<Param> params, std::unique_ptr<Block> body);
    bool usesFmt() const;
};

struct Program final : Node {
    std::string className;
    std::vector<std::unique_ptr<MethodDecl>> methods;

    Program(std::string className, std::vector<std::unique_ptr<MethodDecl>> methods);
    bool usesFmt() const;
};

} // namespace jtg
