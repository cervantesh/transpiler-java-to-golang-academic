#include "diagnostics.hpp"
#include "generator.hpp"
#include "parser_driver.hpp"

#include <fstream>
#include <iostream>
#include <stdexcept>
#include <string>

namespace {

void writeFile(const std::string& path, const std::string& contents) {
    std::ofstream output(path, std::ios::binary);
    if (!output) {
        throw std::runtime_error("could not open output file: " + path);
    }

    output << contents;
}

} // namespace

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "transpiler-java-to-golang-academic\n";
        std::cerr << "usage: javago <input.java> <output.go>\n";
        return 64;
    }

    try {
        const auto diagnostics = jtg::detectUnsupportedFeatures(argv[1]);
        if (!diagnostics.empty()) {
            for (const auto& diagnostic : diagnostics) {
                std::cerr << "error: " << jtg::formatDiagnostic(diagnostic) << "\n";
            }
            return 1;
        }

        auto program = jtg::parseJavaFile(argv[1]);
        const jtg::GoGenerator generator;
        writeFile(argv[2], generator.generate(*program));
        return 0;
    } catch (const std::exception& error) {
        std::cerr << "error: " << error.what() << "\n";
        return 1;
    }
}
