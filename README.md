# transpiler-java-to-golang-academic

Academic Java-to-Go transpiler built with Flex, Bison, C++, and Go tooling.

This repository is written as a class project submission. Its purpose is not to replace a production Java compiler, but to demonstrate practical knowledge of lexical analysis, parsing, abstract syntax trees, code generation, and compiler-style verification.

## Project Objective

The project translates a small, controlled subset of Java into valid Go code.

The implemented compiler pipeline is:

```text
Java source
  -> Flex lexer
  -> Bison parser
  -> C++ AST
  -> deterministic Go generator
  -> gofmt
  -> go run / golden tests
```

The design intentionally follows the spirit of a traditional academic compiler project while using a cleaner structure than printing target code directly from grammar rules. The parser builds an AST first, and the Go generator emits code from that AST.

## What This Demonstrates

This project demonstrates:

- Tokenization with Flex.
- Grammar-based parsing with Bison.
- Use of modern Bison features such as location tracking and detailed parse errors.
- AST construction in C++ using ownership-oriented data structures.
- Separation between parsing and code generation.
- Translation from Java syntax into Go syntax.
- Golden-file testing for compiler output.
- Validation of generated Go with `gofmt` and `go run`.
- Error reporting with line and column information for unsupported or invalid input.

## Why Flex And Bison

Flex and Bison are classic compiler-construction tools. They are useful in this project because they make the compiler stages visible:

- Flex defines how raw Java text becomes tokens.
- Bison defines which token sequences form valid Java-subset programs.
- The semantic actions create AST nodes.
- A separate generator walks the AST and emits Go.

This is intentionally academic. A production Java-to-Go migration tool would need a much larger Java frontend, type resolution, classpath analysis, and project-wide semantic understanding.

## Project Structure

```text
.
|-- build.ps1                  Windows build script
|-- Makefile                   Make-style build for compatible environments
|-- README.md                  Project explanation and usage
|-- docs/
|   |-- ai-assisted-migration.md
|   |-- diagnostics.md
|   `-- evidence/
|       `-- verification-2026-06-16.md
|-- examples/
|   `-- Main.java              Demo Java input
|-- src/
|   |-- lexer.l                Flex lexer
|   |-- parser.y               Bison parser
|   |-- ast.hpp / ast.cpp      AST node model
|   |-- diagnostics.hpp / .cpp Unsupported-feature diagnostics
|   |-- generator.hpp / .cpp   AST-to-Go code generator
|   |-- parser_driver.hpp      Parser facade
|   `-- main.cpp               CLI entry point
|-- test.ps1                   Golden-test runner
`-- tests/
    |-- fixtures/              Java test inputs
    `-- expected/              Expected formatted Go outputs
```

Generated files are written to `build/` and `tests/generated/`, which are intentionally ignored by Git.

## Supported Java Subset

The current version supports:

- One public class.
- Static methods.
- `public static void main(String[] args)`.
- Types: `int`, `double`, `boolean`, `String`, `void`.
- Method parameters and return values.
- Variable declarations:
  - `int x;`
  - `int x = 5;`
- Assignments:
  - `x = x + 1;`
- Expressions:
  - identifiers and literals
  - `+`, `-`, `*`, `/`
  - `<`, `>`, `<=`, `>=`, `==`, `!=`
  - `&&`, `||`, `!`
  - parenthesized expressions
- Control flow:
  - `if (...) { ... } else { ... }`
  - `while (...) { ... }`
- Output:
  - `System.out.println(expr);`
- Comments:
  - `// ...`
  - `/* ... */`

Unsupported features include objects, `new`, inheritance, interfaces, packages, imports, class fields, general arrays, exceptions, generics, lambdas, annotations, overloading, reflection, and Java standard-library translation.

Unsupported features are detected before parsing when possible and reported as structured `JTG` diagnostics with line, column, feature name, and recommendation. See [docs/diagnostics.md](docs/diagnostics.md).

## Translation Rules

The transpiler uses deterministic mappings:

| Java | Go |
| --- | --- |
| `public class Main { ... }` | class wrapper is not emitted |
| `public static void main(String[] args)` | `func main()` |
| static Java method | top-level Go function |
| `int` | `int` |
| `double` | `float64` |
| `boolean` | `bool` |
| `String` | `string` |
| `void` | no return type |
| `while (condition)` | `for condition` |
| `System.out.println(x)` | `fmt.Println(x)` |

The generator only imports `fmt` when the AST contains a print statement.

## Example

Input Java:

```java
public class Main {
    public static void main(String[] args) {
        int x = 3;
        while (x < 5) {
            x = x + 1;
        }

        if (x >= 5) {
            System.out.println(add(x, 2));
        } else {
            System.out.println(0);
        }
    }

    public static int add(int a, int b) {
        return a + b;
    }
}
```

Generated Go:

```go
package main

import "fmt"

func main() {
	var x int = 3
	for x < 5 {
		x = x + 1
	}
	if x >= 5 {
		fmt.Println(add(x, 2))
	} else {
		fmt.Println(0)
	}
}

func add(a int, b int) int {
	return a + b
}
```

Program output:

```text
7
```

## Build

Windows PowerShell:

```powershell
.\build.ps1
```

Manual equivalent:

```powershell
bison -d -o build\parser.cpp src\parser.y
flex -o build\lexer.cpp src\lexer.l
g++ -std=c++17 -Isrc -Ibuild build\parser.cpp build\lexer.cpp src\ast.cpp src\diagnostics.cpp src\generator.cpp src\main.cpp -o build\javago.exe
```

The full build script also compiles `src\diagnostics.cpp`; use `.\build.ps1` as the source of truth for local builds.

If `flex` or `bison` is missing, install WinFlexBison:

```powershell
scoop install winflexbison
```

or:

```powershell
choco install winflexbison3
```

## Run

```powershell
.\build\javago.exe examples\Main.java build\Main.go
gofmt -w build\Main.go
go run build\Main.go
```

Expected output:

```text
7
```

## Test

Run the golden-test suite:

```powershell
.\test.ps1
```

The test runner:

- Rebuilds the transpiler.
- Executes exactly 30 evidence cases.
- Transpiles Java fixtures from `tests/fixtures`.
- Formats generated Go with `gofmt`.
- Compares generated Go against `tests/expected`.
- Runs generated Go programs with `go run`.
- Verifies syntax errors include line and column details.
- Verifies unsupported Java features fail with structured `JTG` diagnostics and recommendations.

The 30-case suite includes 20 supported Java-to-Go translations, one syntax-error case, and nine unsupported-feature diagnostics.

## Verification Evidence

Verification evidence is stored in:

[docs/evidence/verification-2026-06-16.md](docs/evidence/verification-2026-06-16.md)

That file records the tool versions, build output, golden-test output, manual test output, and a negative syntax/error test.

## Known Limitations

This project is intentionally small. It does not perform full Java semantic analysis, classpath resolution, object modeling, method overload resolution, or library migration.

Examples of unsupported input should fail with a structured diagnostic or parser error instead of producing misleading Go code. For example, class fields are rejected before parsing with `JTG1016`.

## AI-Assisted Migration Note

The transpiler should stay deterministic by default. AI can be added later as an optional sidecar for migration reports, diagnostic explanations, unsupported-code suggestions, golden-test assistance, and idiomatic Go review.

See [docs/ai-assisted-migration.md](docs/ai-assisted-migration.md) for the proposed architecture, guardrails, file layout, and implementation order.
