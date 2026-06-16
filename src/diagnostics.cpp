#include "diagnostics.hpp"

#include <cctype>
#include <fstream>
#include <regex>
#include <sstream>
#include <stdexcept>
#include <string>
#include <unordered_map>
#include <vector>

namespace jtg {
namespace {

struct Line {
    int number;
    std::string text;
};

bool isIdentifierChar(char value) {
    return std::isalnum(static_cast<unsigned char>(value)) || value == '_';
}

std::string readFile(const std::string& path) {
    std::ifstream input(path, std::ios::binary);
    if (!input) {
        throw std::runtime_error("could not open input file: " + path);
    }

    std::ostringstream buffer;
    buffer << input.rdbuf();
    return buffer.str();
}

std::string maskCommentsAndLiterals(const std::string& source) {
    std::string masked = source;
    bool inLineComment = false;
    bool inBlockComment = false;
    bool inString = false;
    bool inChar = false;
    bool escaped = false;

    for (size_t index = 0; index < source.size(); ++index) {
        const char current = source[index];
        const char next = index + 1 < source.size() ? source[index + 1] : '\0';

        if (inLineComment) {
            if (current == '\n') {
                inLineComment = false;
            } else {
                masked[index] = ' ';
            }
            continue;
        }

        if (inBlockComment) {
            if (current == '*' && next == '/') {
                masked[index] = ' ';
                masked[index + 1] = ' ';
                ++index;
                inBlockComment = false;
            } else if (current != '\n') {
                masked[index] = ' ';
            }
            continue;
        }

        if (inString) {
            if (current != '\n') {
                masked[index] = ' ';
            }
            if (escaped) {
                escaped = false;
            } else if (current == '\\') {
                escaped = true;
            } else if (current == '"') {
                inString = false;
            }
            continue;
        }

        if (inChar) {
            if (current != '\n') {
                masked[index] = ' ';
            }
            if (escaped) {
                escaped = false;
            } else if (current == '\\') {
                escaped = true;
            } else if (current == '\'') {
                inChar = false;
            }
            continue;
        }

        if (current == '/' && next == '/') {
            masked[index] = ' ';
            masked[index + 1] = ' ';
            ++index;
            inLineComment = true;
            continue;
        }

        if (current == '/' && next == '*') {
            masked[index] = ' ';
            masked[index + 1] = ' ';
            ++index;
            inBlockComment = true;
            continue;
        }

        if (current == '"') {
            masked[index] = ' ';
            inString = true;
            continue;
        }

        if (current == '\'') {
            masked[index] = ' ';
            inChar = true;
            continue;
        }
    }

    return masked;
}

std::vector<Line> splitLines(const std::string& source) {
    std::vector<Line> lines;
    std::istringstream stream(source);
    std::string text;
    int number = 1;
    while (std::getline(stream, text)) {
        lines.push_back(Line{number, text});
        ++number;
    }
    if (!source.empty() && source.back() == '\n') {
        return lines;
    }
    if (source.empty()) {
        lines.push_back(Line{1, ""});
    }
    return lines;
}

size_t findKeyword(const std::string& line, const std::string& keyword) {
    size_t position = line.find(keyword);
    while (position != std::string::npos) {
        const bool leftOk = position == 0 || !isIdentifierChar(line[position - 1]);
        const size_t after = position + keyword.size();
        const bool rightOk = after >= line.size() || !isIdentifierChar(line[after]);
        if (leftOk && rightOk) {
            return position;
        }
        position = line.find(keyword, position + 1);
    }
    return std::string::npos;
}

bool containsKeyword(const std::string& line, const std::string& keyword) {
    return findKeyword(line, keyword) != std::string::npos;
}

std::string trimLeft(const std::string& value) {
    size_t index = 0;
    while (index < value.size() && std::isspace(static_cast<unsigned char>(value[index]))) {
        ++index;
    }
    return value.substr(index);
}

void addDiagnostic(
    std::vector<Diagnostic>& diagnostics,
    const std::string& file,
    int line,
    size_t zeroBasedColumn,
    std::string code,
    std::string feature,
    std::string recommendation
) {
    diagnostics.push_back(Diagnostic{
        file,
        line,
        static_cast<int>(zeroBasedColumn) + 1,
        std::move(code),
        feature,
        "unsupported feature: " + feature,
        std::move(recommendation),
    });
}

int braceDelta(const std::string& line) {
    int delta = 0;
    for (char value : line) {
        if (value == '{') {
            ++delta;
        } else if (value == '}') {
            --delta;
        }
    }
    return delta;
}

bool isAllowedMainArrayParameter(const std::string& line) {
    return line.find("main") != std::string::npos && line.find("String[] args") != std::string::npos;
}

bool looksLikeClassField(const std::string& line) {
    static const std::regex fieldPattern(
        R"(^\s*((public|private|protected|static|final)\s+)*(int|double|boolean|String|[A-Z][A-Za-z0-9_]*)\s+[A-Za-z_][A-Za-z0-9_]*\s*(=|;|,))"
    );
    return std::regex_search(line, fieldPattern) && line.find('(') == std::string::npos;
}

bool looksLikeMethodSignature(const std::string& line) {
    return line.find('(') != std::string::npos && line.find(')') != std::string::npos && !containsKeyword(line, "class");
}

std::string methodNameFromSignature(const std::string& line) {
    const size_t paren = line.find('(');
    if (paren == std::string::npos) {
        return "";
    }

    size_t end = paren;
    while (end > 0 && std::isspace(static_cast<unsigned char>(line[end - 1]))) {
        --end;
    }

    size_t start = end;
    while (start > 0 && isIdentifierChar(line[start - 1])) {
        --start;
    }

    return line.substr(start, end - start);
}

bool looksLikeGenericUsage(const std::string& line) {
    static const std::regex genericPattern(
        R"(([A-Za-z_][A-Za-z0-9_\.]*)\s*<\s*([A-Za-z_?][A-Za-z0-9_?\.]*))"
    );
    return std::regex_search(line, genericPattern) && line.find('>') != std::string::npos;
}

} // namespace

std::vector<Diagnostic> detectUnsupportedFeatures(const std::string& path) {
    const std::string source = readFile(path);
    const std::string masked = maskCommentsAndLiterals(source);
    const std::vector<Line> lines = splitLines(masked);
    std::vector<Diagnostic> diagnostics;
    std::unordered_map<std::string, int> methodLines;
    int braceDepth = 0;

    for (const Line& line : lines) {
        const std::string trimmed = trimLeft(line.text);

        const struct {
            const char* keyword;
            const char* code;
            const char* feature;
            const char* recommendation;
        } keywordRules[] = {
            {"package", "JTG1001", "package declarations", "Remove the package declaration for the academic subset or add package-to-module mapping."},
            {"import", "JTG1002", "import declarations", "Inline supported code or add import mapping before transpiling."},
            {"interface", "JTG1003", "interfaces", "Add an interface-to-Go-interface lowering strategy before using Java interfaces."},
            {"extends", "JTG1004", "inheritance", "Rewrite inheritance as composition or add an object model lowering pass."},
            {"implements", "JTG1005", "interface implementation", "Add Java interface mapping before transpiling implements clauses."},
            {"new", "JTG1006", "object construction", "Add class/constructor lowering before using new expressions."},
            {"try", "JTG1007", "try/catch exceptions", "Design explicit Go error returns before transpiling exceptions."},
            {"catch", "JTG1008", "catch blocks", "Design explicit Go error returns before transpiling exceptions."},
            {"finally", "JTG1009", "finally blocks", "Map cleanup to defer before transpiling finally blocks."},
            {"throw", "JTG1010", "throw statements", "Map thrown exceptions to Go error values before transpiling throw."},
            {"throws", "JTG1011", "throws declarations", "Map checked exceptions to explicit Go error returns."},
        };

        for (const auto& rule : keywordRules) {
            const size_t position = findKeyword(line.text, rule.keyword);
            if (position != std::string::npos) {
                addDiagnostic(diagnostics, path, line.number, position, rule.code, rule.feature, rule.recommendation);
            }
        }

        const size_t lambdaPosition = line.text.find("->");
        if (lambdaPosition != std::string::npos) {
            addDiagnostic(diagnostics, path, line.number, lambdaPosition, "JTG1012", "lambdas", "Rewrite the lambda as a named method or add functional-interface lowering.");
        }

        const size_t annotationPosition = trimmed.empty() ? std::string::npos : line.text.find('@');
        if (annotationPosition != std::string::npos) {
            addDiagnostic(diagnostics, path, line.number, annotationPosition, "JTG1013", "annotations", "Remove annotations or add an annotation policy for migration metadata.");
        }

        if (looksLikeGenericUsage(line.text)) {
            addDiagnostic(diagnostics, path, line.number, line.text.find('<'), "JTG1014", "generics", "Specialize the generic type manually or add a Java-to-Go type-parameter mapping pass.");
        }

        if (line.text.find('[') != std::string::npos && !isAllowedMainArrayParameter(line.text)) {
            addDiagnostic(diagnostics, path, line.number, line.text.find('['), "JTG1015", "arrays and indexing", "Add array declarations, indexing, and length lowering before using arrays.");
        }

        if (braceDepth == 1 && looksLikeClassField(line.text)) {
            addDiagnostic(diagnostics, path, line.number, line.text.find_first_not_of(" \t"), "JTG1016", "class fields", "Add struct field lowering before transpiling Java fields.");
        }

        if (braceDepth == 1 && looksLikeMethodSignature(line.text)) {
            const std::string methodName = methodNameFromSignature(line.text);
            if (!containsKeyword(line.text, "static")) {
                addDiagnostic(diagnostics, path, line.number, line.text.find(methodName), "JTG1017", "instance methods", "Add Go receiver generation before transpiling instance methods.");
            }

            if (!methodName.empty()) {
                const auto inserted = methodLines.emplace(methodName, line.number);
                if (!inserted.second) {
                    addDiagnostic(diagnostics, path, line.number, line.text.find(methodName), "JTG1018", "method overloading", "Rename overloaded methods or add overload name mangling before generating Go.");
                }
            }
        }

        braceDepth += braceDelta(line.text);
        if (braceDepth < 0) {
            braceDepth = 0;
        }
    }

    return diagnostics;
}

std::string formatDiagnostic(const Diagnostic& diagnostic) {
    std::ostringstream out;
    out << diagnostic.file << ":" << diagnostic.line << ":" << diagnostic.column << ": "
        << diagnostic.code << ": " << diagnostic.message;
    if (!diagnostic.recommendation.empty()) {
        out << "\n  recommendation: " << diagnostic.recommendation;
    }
    return out.str();
}

} // namespace jtg
