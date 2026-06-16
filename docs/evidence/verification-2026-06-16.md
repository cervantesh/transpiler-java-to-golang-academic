# Verification Evidence - 2026-06-16

This file records reproducible evidence for the academic Java-to-Go transpiler implementation.

## Environment

```text
bison (GNU Bison) 3.8.2
win_flex.exe 2.6.4
g++.exe (GCC) 15.2.0
go version go1.25.6 windows/amd64
```

## Full 30-Case Test Run

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
PASS arithmetic_precedence
PASS parenthesized_expression
PASS unary_minus
PASS boolean_and_or
PASS boolean_not
PASS equality_inequality
PASS comparison_bounds
PASS string_variable
PASS double_arithmetic
PASS comments_handling
PASS no_fmt_import
PASS return_without_value
PASS static_void_method_call
PASS nested_control
PASS multiple_parameters
PASS syntax_error
PASS unsupported_field
PASS unsupported_package_import
PASS unsupported_exception
PASS unsupported_instance_method
PASS unsupported_overload
PASS unsupported_interface
PASS unsupported_inheritance
PASS unsupported_generics
PASS unsupported_array_indexing
PASS evidence_case_count => 30
```

## Evidence Case Matrix

| # | Case | Type | Evidence purpose |
| ---: | --- | --- | --- |
| 1 | `hello_print` | supported | Emits `System.out.println` as `fmt.Println`. |
| 2 | `variables` | supported | Translates primitive variable declarations and assignments. |
| 3 | `if_else` | supported | Emits Java `if/else` as Go `if/else`. |
| 4 | `while_loop` | supported | Emits Java `while` as Go `for condition`. |
| 5 | `method_return` | supported | Emits static Java methods with return values. |
| 6 | `arithmetic_precedence` | supported | Preserves operator precedence for arithmetic expressions. |
| 7 | `parenthesized_expression` | supported | Preserves explicit parentheses in expressions. |
| 8 | `unary_minus` | supported | Emits unary negative numeric expressions. |
| 9 | `boolean_and_or` | supported | Emits `&&` and `||` boolean expressions. |
| 10 | `boolean_not` | supported | Emits unary `!` boolean expressions. |
| 11 | `equality_inequality` | supported | Emits `==` and `!=` comparisons. |
| 12 | `comparison_bounds` | supported | Emits `<`, `>`, `<=`, and `>=` comparisons. |
| 13 | `string_variable` | supported | Maps Java `String` variables to Go `string`. |
| 14 | `double_arithmetic` | supported | Maps Java `double` arithmetic to Go `float64`. |
| 15 | `comments_handling` | supported | Ignores line and block comments in the lexer. |
| 16 | `no_fmt_import` | supported | Avoids importing `fmt` when there is no print statement. |
| 17 | `return_without_value` | supported | Emits bare `return` in `void` methods. |
| 18 | `static_void_method_call` | supported | Emits a static `void` method call used as a statement. |
| 19 | `nested_control` | supported | Emits nested `while` and `if/else` blocks. |
| 20 | `multiple_parameters` | supported | Emits static methods with multiple parameters. |
| 21 | `syntax_error` | negative | Invalid Java reports a parser error with line and column. |
| 22 | `unsupported_field` | negative | Class fields are rejected with `JTG1016`. |
| 23 | `unsupported_package_import` | negative | Package declarations are rejected with `JTG1001`. |
| 24 | `unsupported_exception` | negative | Try/catch usage is rejected with `JTG1007`. |
| 25 | `unsupported_instance_method` | negative | Instance methods are rejected with `JTG1017`. |
| 26 | `unsupported_overload` | negative | Method overloads are rejected with `JTG1018`. |
| 27 | `unsupported_interface` | negative | Interfaces are rejected with `JTG1003`. |
| 28 | `unsupported_inheritance` | negative | Inheritance is rejected with `JTG1004`. |
| 29 | `unsupported_generics` | negative | Generic type usage is rejected with `JTG1014`. |
| 30 | `unsupported_array_indexing` | negative | Arrays and indexing are rejected with `JTG1015`. |

## Transpiler Improvement Added During Evidence Expansion

The 30-case suite exposed a missing supported behavior: the parser accepted method calls inside expressions, but not static `void` method calls used as statements.

Failing input before the fix:

```java
public class StaticVoidMethodCall {
    public static void greet() {
        System.out.println("hi");
    }

    public static void main(String[] args) {
        greet();
    }
}
```

The fix added an `ExprStmt` AST node, a Bison grammar rule for simple call statements, and Go generation for expression statements.

Generated Go:

```go
package main

import "fmt"

func greet() {
	fmt.Println("hi")
}

func main() {
	greet()
}
```

## Reproducibility Notes

Generated artifacts are intentionally excluded from source control:

- `build/`
- `tests/generated/`

To reproduce the evidence:

```powershell
.\build.ps1
.\test.ps1
```
