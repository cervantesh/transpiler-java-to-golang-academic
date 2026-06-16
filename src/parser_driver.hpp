#pragma once

#include "ast.hpp"

#include <memory>
#include <string>

namespace jtg {

std::unique_ptr<Program> parseJavaFile(const std::string& path);

} // namespace jtg
