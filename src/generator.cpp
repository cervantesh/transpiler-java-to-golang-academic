#include "generator.hpp"

#include <sstream>
#include <stdexcept>

namespace jtg {

std::string GoGenerator::generate(const Program& program) const {
    std::ostringstream out;
    out << "package main\n\n";

    if (program.usesFmt()) {
        out << "import \"fmt\"\n\n";
    }

    for (const auto& method : program.methods) {
        emitMethod(out, *method);
        out << "\n";
    }

    return out.str();
}

void GoGenerator::emitMethod(std::ostream& out, const MethodDecl& method) const {
    out << "func " << method.name << "(";

    if (method.name != "main") {
        for (size_t index = 0; index < method.params.size(); ++index) {
            if (index > 0) {
                out << ", ";
            }
            out << method.params[index].name << " " << method.params[index].type.goName;
        }
    }

    out << ")";
    if (!method.returnType.isVoid) {
        out << " " << method.returnType.goName;
    }
    out << " {\n";
    emitBlock(out, *method.body, 1);
    out << "}\n";
}

void GoGenerator::emitBlock(std::ostream& out, const Block& block, int indentLevel) const {
    for (const auto& statement : block.statements) {
        emitStmt(out, *statement, indentLevel);
    }
}

void GoGenerator::emitStmt(std::ostream& out, const Stmt& stmt, int indentLevel) const {
    const auto padding = indent(indentLevel);

    if (const auto* varDecl = dynamic_cast<const VarDecl*>(&stmt)) {
        out << padding << "var " << varDecl->name << " " << varDecl->type.goName;
        if (varDecl->initializer) {
            out << " = " << emitExpr(*varDecl->initializer);
        }
        out << "\n";
        return;
    }

    if (const auto* assign = dynamic_cast<const AssignStmt*>(&stmt)) {
        out << padding << assign->name << " = " << emitExpr(*assign->value) << "\n";
        return;
    }

    if (const auto* exprStmt = dynamic_cast<const ExprStmt*>(&stmt)) {
        out << padding << emitExpr(*exprStmt->expr) << "\n";
        return;
    }

    if (const auto* print = dynamic_cast<const PrintStmt*>(&stmt)) {
        out << padding << "fmt.Println(" << emitExpr(*print->value) << ")\n";
        return;
    }

    if (const auto* ret = dynamic_cast<const ReturnStmt*>(&stmt)) {
        out << padding << "return";
        if (ret->value) {
            out << " " << emitExpr(*ret->value);
        }
        out << "\n";
        return;
    }

    if (const auto* ifStmt = dynamic_cast<const IfStmt*>(&stmt)) {
        out << padding << "if " << emitExpr(*ifStmt->condition) << " {\n";
        emitBlock(out, *ifStmt->thenBlock, indentLevel + 1);
        out << padding << "}";
        if (ifStmt->elseBlock) {
            out << " else {\n";
            emitBlock(out, *ifStmt->elseBlock, indentLevel + 1);
            out << padding << "}";
        }
        out << "\n";
        return;
    }

    if (const auto* whileStmt = dynamic_cast<const WhileStmt*>(&stmt)) {
        out << padding << "for " << emitExpr(*whileStmt->condition) << " {\n";
        emitBlock(out, *whileStmt->body, indentLevel + 1);
        out << padding << "}\n";
        return;
    }

    throw std::runtime_error("unknown statement node while generating Go");
}

std::string GoGenerator::emitExpr(const Expr& expr) const {
    if (const auto* literal = dynamic_cast<const IntLiteralExpr*>(&expr)) {
        return literal->value;
    }

    if (const auto* literal = dynamic_cast<const DoubleLiteralExpr*>(&expr)) {
        return literal->value;
    }

    if (const auto* literal = dynamic_cast<const StringLiteralExpr*>(&expr)) {
        return literal->value;
    }

    if (const auto* literal = dynamic_cast<const BoolLiteralExpr*>(&expr)) {
        return literal->value ? "true" : "false";
    }

    if (const auto* identifier = dynamic_cast<const IdentifierExpr*>(&expr)) {
        return identifier->name;
    }

    if (const auto* call = dynamic_cast<const CallExpr*>(&expr)) {
        std::ostringstream out;
        out << call->callee << "(";
        for (size_t index = 0; index < call->args.size(); ++index) {
            if (index > 0) {
                out << ", ";
            }
            out << emitExpr(*call->args[index]);
        }
        out << ")";
        return out.str();
    }

    if (const auto* parenthesized = dynamic_cast<const ParenthesizedExpr*>(&expr)) {
        return "(" + emitExpr(*parenthesized->expr) + ")";
    }

    if (const auto* unary = dynamic_cast<const UnaryExpr*>(&expr)) {
        return unary->op + emitExpr(*unary->expr);
    }

    if (const auto* binary = dynamic_cast<const BinaryExpr*>(&expr)) {
        return emitExpr(*binary->left) + " " + binary->op + " " + emitExpr(*binary->right);
    }

    throw std::runtime_error("unknown expression node while generating Go");
}

std::string GoGenerator::indent(int indentLevel) const {
    return std::string(static_cast<size_t>(indentLevel) * 4, ' ');
}

} // namespace jtg
