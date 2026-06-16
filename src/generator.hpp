#pragma once

#include "ast.hpp"

#include <iosfwd>
#include <string>

namespace jtg {

class GoGenerator {
public:
    std::string generate(const Program& program) const;

private:
    void emitMethod(std::ostream& out, const MethodDecl& method) const;
    void emitBlock(std::ostream& out, const Block& block, int indentLevel) const;
    void emitStmt(std::ostream& out, const Stmt& stmt, int indentLevel) const;
    std::string emitExpr(const Expr& expr) const;
    std::string indent(int indentLevel) const;
};

} // namespace jtg
