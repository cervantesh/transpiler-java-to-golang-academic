# Test Cases

The project includes exactly 30 evidence cases. `test.ps1` enforces this count.

## Supported Translation Cases

| # | Fixture | Purpose |
| ---: | --- | --- |
| 1 | `hello_print.java` | Converts `System.out.println` into `fmt.Println`. |
| 2 | `variables.java` | Covers primitive variable declarations and assignments. |
| 3 | `if_else.java` | Converts Java `if/else` into Go `if/else`. |
| 4 | `while_loop.java` | Converts Java `while` into Go `for condition`. |
| 5 | `method_return.java` | Converts a static method with return value. |
| 6 | `arithmetic_precedence.java` | Preserves arithmetic precedence. |
| 7 | `parenthesized_expression.java` | Preserves explicit parentheses. |
| 8 | `unary_minus.java` | Converts unary negative numbers. |
| 9 | `boolean_and_or.java` | Converts `&&` and `||`. |
| 10 | `boolean_not.java` | Converts unary `!`. |
| 11 | `equality_inequality.java` | Converts `==` and `!=`. |
| 12 | `comparison_bounds.java` | Converts `<`, `>`, `<=`, and `>=`. |
| 13 | `string_variable.java` | Maps Java `String` to Go `string`. |
| 14 | `double_arithmetic.java` | Maps Java `double` to Go `float64`. |
| 15 | `comments_handling.java` | Ignores line and block comments. |
| 16 | `no_fmt_import.java` | Avoids `fmt` when print is not used. |
| 17 | `return_without_value.java` | Converts bare `return` in a void method. |
| 18 | `static_void_method_call.java` | Converts a static void method call statement. |
| 19 | `nested_control.java` | Covers nested `while` and `if/else`. |
| 20 | `multiple_parameters.java` | Converts methods with multiple parameters. |

## Negative Evidence Cases

| # | Fixture | Expected result |
| ---: | --- | --- |
| 21 | `syntax_error.java` | Parser error with line and column. |
| 22 | `unsupported_field.java` | `JTG1016`: class fields are unsupported. |
| 23 | `unsupported_package_import.java` | `JTG1001`: package declarations are unsupported. |
| 24 | `unsupported_exception.java` | `JTG1007`: try/catch exceptions are unsupported. |
| 25 | `unsupported_instance_method.java` | `JTG1017`: instance methods are unsupported. |
| 26 | `unsupported_overload.java` | `JTG1018`: method overloading is unsupported. |
| 27 | `unsupported_interface.java` | `JTG1003`: interfaces are unsupported. |
| 28 | `unsupported_inheritance.java` | `JTG1004`: inheritance is unsupported. |
| 29 | `unsupported_generics.java` | `JTG1014`: generics are unsupported. |
| 30 | `unsupported_array_indexing.java` | `JTG1015`: arrays and indexing are unsupported. |

Run:

```powershell
.\test.ps1
```
