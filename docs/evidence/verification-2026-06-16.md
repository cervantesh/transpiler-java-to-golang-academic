# Verification Evidence - 2026-06-16

This file records evidence for the academic Java-to-Go transpiler implementation.

## Project

- Project name: `transpiler-java-to-golang-academic`
- Workspace: `C:\dev\transpiler`
- Purpose: demonstrate a Flex/Bison compiler pipeline that translates a small Java subset into Go.

## Toolchain Versions

Command:

```powershell
bison --version | Select-Object -First 1
flex --version
g++ --version | Select-Object -First 1
go version
```

Observed output:

```text
bison (GNU Bison) 3.8.2
win_flex.exe 2.6.4
g++.exe (GCC) 15.2.0
go version go1.25.6 windows/amd64
```

## Golden Test Suite

Command:

```powershell
.\test.ps1
```

Observed output:

```text
Built C:\dev\transpiler\build\javago.exe
PASS hello_print
PASS variables
PASS if_else
PASS while_loop
PASS method_return
PASS syntax_error
```

Coverage represented by this suite:

- `hello_print`: translates `System.out.println("hello")` into `fmt.Println("hello")`.
- `variables`: translates primitive declarations, assignments, and prints.
- `if_else`: translates Java `if/else` into Go `if/else`.
- `while_loop`: translates Java `while` into Go `for`.
- `method_return`: translates a static Java method into a top-level Go function with a return value.
- `syntax_error`: verifies invalid Java fails with a line/column parser error.

## Main Example Verification

Command:

```powershell
.\build\javago.exe examples\Main.java build\Main.go
gofmt -w build\Main.go
go run build\Main.go
```

Observed output:

```text
7
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

## Additional Manual Tests

The following manual cases were transpiled, formatted with `gofmt`, executed with `go run`, and checked against expected output.

Observed output:

```text
PASS arithmetic_parentheses => 20
PASS comments_boolean => ok
PASS double_method => 4
PASS var_without_initializer => 5
PASS nested_control => 2
PASS unsupported_field rejected => error: parse error at line 2, column 5: syntax error, unexpected INT, expecting PUBLIC or STATIC
```

Manual coverage:

- Parenthesized arithmetic preserves precedence.
- Line comments and block comments are ignored.
- Boolean expressions with `&&` and `!` translate correctly.
- `double` maps to Go `float64`.
- Variables can be declared before assignment.
- Nested `while` and `if/else` blocks generate valid Go.
- Unsupported class fields are rejected with location information.

## Reproducibility Notes

Generated artifacts are intentionally excluded from source control:

- `build/`
- `tests/generated/`

To reproduce the evidence:

```powershell
.\build.ps1
.\test.ps1
.\build\javago.exe examples\Main.java build\Main.go
gofmt -w build\Main.go
go run build\Main.go
```
