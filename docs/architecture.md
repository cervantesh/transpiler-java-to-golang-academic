# Architecture

This project uses a classic compiler pipeline, but keeps the stages separated so the code is easier to explain in class.

```text
Java source file
  -> unsupported-feature diagnostics
  -> Flex lexer
  -> Bison parser
  -> C++ AST
  -> Go generator
  -> gofmt and go run verification
```

## Source Modules

| File | Responsibility |
| --- | --- |
| `src/main.cpp` | CLI entry point. Runs diagnostics, parsing, generation, and file writing. |
| `src/diagnostics.hpp` / `src/diagnostics.cpp` | Pre-parser scan for known unsupported Java features with stable `JTG` codes. |
| `src/lexer.l` | Flex scanner. Converts Java source text into parser tokens. |
| `src/parser.y` | Bison grammar. Accepts the academic Java subset and builds AST nodes. |
| `src/ast.hpp` / `src/ast.cpp` | AST node definitions used between parsing and generation. |
| `src/generator.hpp` / `src/generator.cpp` | Converts AST nodes into deterministic Go source. |
| `src/parser_driver.hpp` | Small parser facade used by the CLI. |

## Design Choices

- The parser builds an AST instead of printing Go directly from grammar actions.
- Unsupported Java features are rejected before parsing when they can be detected reliably.
- Generated Go is intentionally mechanical and deterministic.
- `fmt` is imported only when a print statement is present.
- Java classes are containers for static methods in this academic subset; no Go struct is emitted.
- `while` is emitted as Go `for condition`.

## Data Flow

1. `main.cpp` receives an input Java path and output Go path.
2. `diagnostics.cpp` scans for unsupported constructs such as packages, imports, fields, exceptions, arrays, generics, and overloads.
3. `lexer.l` tokenizes the source for Bison.
4. `parser.y` validates the supported Java subset and builds a `Program` AST.
5. `generator.cpp` walks the AST and emits Go source.
6. `test.ps1` formats generated Go with `gofmt`, compares it against golden files, and runs supported programs with `go run`.

## Academic Boundary

This is not a full Java compiler. It deliberately avoids full type checking, classpath resolution, object construction, inheritance, and library migration. Those features are documented as unsupported and verified through negative evidence cases.
