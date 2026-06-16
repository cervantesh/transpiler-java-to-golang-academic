#pragma once

#include <string>
#include <vector>

namespace jtg {

struct Diagnostic {
    std::string file;
    int line;
    int column;
    std::string code;
    std::string feature;
    std::string message;
    std::string recommendation;
};

std::vector<Diagnostic> detectUnsupportedFeatures(const std::string& path);
std::string formatDiagnostic(const Diagnostic& diagnostic);

} // namespace jtg
