# Verification Evidence - 2026-06-16

## Environment

```text
bison (GNU Bison) 3.8.2
win_flex.exe 2.6.4
g++.exe (GCC) 15.2.0
go version go1.25.6 windows/amd64
```

## Full Test Run

Command:

```powershell
.\test.ps1
```

Output:

```text
Built C:\dev\transpiler\build\javago.exe
PASS hello_print
PASS variables
PASS if_else
PASS while_loop
PASS method_return
PASS syntax_error
PASS unsupported_field
PASS unsupported_package_import
PASS unsupported_exception
PASS unsupported_instance_method
PASS unsupported_overload
```

## Structured Unsupported-Feature Diagnostic

Command:

```powershell
.\build\javago.exe tests\fixtures\unsupported_field.java tests\generated\manual_unsupported_field.go
```

Exit code: `1`

Output:

```text
error: tests\fixtures\unsupported_field.java:2:5: JTG1016: unsupported feature: class fields
  recommendation: Add struct field lowering before transpiling Java fields.
```

## Phase 1 Completion Evidence

The first AI-assisted migration implementation phase is complete:

- `src\diagnostics.hpp` defines the structured diagnostic shape.
- `src\diagnostics.cpp` detects common unsupported Java features before parsing.
- `src\main.cpp` emits structured diagnostics and stops before writing misleading Go output.
- `test.ps1` verifies unsupported features fail with stable `JTG` codes, feature names, and recommendations.
- `docs\diagnostics.md` documents the diagnostic format and code table.
- `docs\ai-assisted-migration.md` marks the structured-diagnostics phase as completed.
