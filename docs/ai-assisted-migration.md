# AI-Assisted Migration Layer

This document describes how to use AI in this Java-to-Go transpiler without making the compiler output non-deterministic.

The core transpiler should remain a classic compiler pipeline:

```text
Java source -> lexer/parser -> AST -> semantic checks -> Go generator -> gofmt/tests
```

AI should live beside that pipeline as an optional migration assistant:

```text
Java source
  -> deterministic transpiler
  -> formatted Go
  -> tests

Java source + diagnostics + generated Go
  -> AI sidecar
  -> migration report, explanations, review suggestions, optional draft code
```

## Rule

AI must not be the default source of truth for generated Go.

The deterministic transpiler decides what is supported and what is emitted. AI can explain, classify, suggest, and help review. Any AI-generated code must be clearly marked as advisory and should not be mixed silently into normal transpiler output.

## Useful AI Features

### 1. Migration Report

Add a report mode that scans Java files and summarizes how hard they are to migrate.

Example command:

```powershell
.\build\javago.exe --report examples\Main.java build\migration-report.md
```

Report contents:

- Files analyzed.
- Supported features found.
- Unsupported features found.
- Risk level per file or method.
- Recommended migration order.
- Transpiler gaps that would unlock the most code.

Example output:

```markdown
# Java To Go Migration Report

## Summary

- Files: 12
- Low-risk methods: 31
- Medium-risk methods: 8
- Blocked methods: 5

## Unsupported Feature Counts

| Feature | Count | Recommendation |
| --- | ---: | --- |
| class fields | 9 | Add struct field lowering |
| arrays | 6 | Add array declarations and indexing |
| exceptions | 4 | Design explicit Go `error` strategy |
| inheritance | 2 | Manual rewrite recommended |
```

### 2. Diagnostic Explainer

When the compiler rejects a Java construct, AI can turn a terse diagnostic into a migration note.

Compiler diagnostic:

```text
OrderService.java:42:13: unsupported feature: try/catch
```

AI explanation:

```text
This method uses Java exceptions. Go does not have try/catch, so the migration needs an explicit error return.

Recommended rewrite shape:

func placeOrder(...) error {
    if err := validateOrder(...); err != nil {
        return err
    }
    return nil
}
```

This should be emitted as a side report, not inserted into generated Go automatically.

### 3. Controlled Fallback Suggestions

For unsupported methods, an opt-in flag can ask AI for a draft Go version.

Example command:

```powershell
.\build\javago.exe --ai-suggest examples\Main.java build\Main.go
```

Generated Go should clearly mark suggested code:

```go
// AI suggestion: review before using.
// Original Java construct was not supported by the deterministic transpiler.
func processOrder() error {
	return fmt.Errorf("manual migration required")
}
```

The default transpilation path should not emit AI suggestions.

### 4. Golden Test Assistance

AI can speed up test authoring by proposing expected Go for new Java fixtures.

Workflow:

1. Developer adds `tests/fixtures/new_case.java`.
2. AI proposes `tests/expected/new_case.go`.
3. Developer reviews and edits expected Go.
4. Deterministic tests compare actual output to the reviewed golden file.

The golden file becomes the truth after review. The test runner should never call AI.

### 5. Idiomatic Go Review

After the deterministic transpiler emits correct but mechanical Go, AI can suggest a cleaner Go rewrite.

Examples:

- Replace Java-style helper classes with package-level functions.
- Replace exception-like flows with explicit `error` returns.
- Suggest `context.Context` for cancellation-heavy APIs.
- Suggest goroutines only when Java code clearly uses concurrency.
- Replace `System.out.println` debugging with structured logging when appropriate.

These suggestions belong in a review report, not in the default generated file.

## Proposed Architecture

Keep AI behind a small interface so the transpiler is not tied to one provider.

```cpp
struct AiRequest {
    std::string task;
    std::string filePath;
    std::string javaSource;
    std::string generatedGo;
    std::string diagnosticsJson;
};

struct AiResponse {
    std::string markdown;
    bool usedModel;
};

class AiProvider {
public:
    virtual ~AiProvider() = default;
    virtual AiResponse run(const AiRequest& request) = 0;
};
```

For the current C++ codebase, the first version can avoid direct API integration and write JSON artifacts that a separate script sends to an AI model.

Example deterministic artifact:

```json
{
  "task": "explain-diagnostics",
  "filePath": "examples/Main.java",
  "diagnostics": [
    {
      "line": 12,
      "column": 8,
      "message": "unsupported feature: class field"
    }
  ],
  "sourceExcerpt": "public class Main { private int count; }"
}
```

This keeps credentials and network behavior out of the compiler binary.

## Suggested Files

For the current repo:

- `docs/ai-assisted-migration.md` - this strategy document.
- `docs/ai-prompts.md` - versioned prompts for reports and explanations.
- `src/diagnostics.hpp` - structured diagnostic type if diagnostics grow beyond parser errors.
- `src/report_generator.hpp` and `src/report_generator.cpp` - deterministic Markdown/JSON report output.
- `scripts/ai_explain.ps1` - optional script that reads JSON diagnostics and calls an AI provider.
- `tests/fixtures/unsupported_*.java` - unsupported feature examples.
- `tests/expected/*.stderr.txt` - deterministic diagnostics that AI can explain.

For a future ANTLR/IR rewrite:

- `src/internal/analysis/report.go`
- `src/internal/ai/provider.go`
- `src/internal/ai/prompts.go`
- `src/internal/ai/offline_provider.go`
- `src/cmd/j2go --report`
- `src/cmd/j2go --ai-suggest`

## Prompt Versioning

Prompts should be stored as source files, not improvised inside code.

Recommended prompt names:

- `migration_report_v1`
- `diagnostic_explainer_v1`
- `unsupported_method_suggestion_v1`
- `idiomatic_go_review_v1`
- `golden_test_proposal_v1`

Each prompt should include:

- The exact Java source or excerpt.
- The deterministic compiler diagnostic.
- The current supported-feature list.
- A warning that unsupported code must be marked as advisory.
- A request to separate facts from suggestions.

## Safety And Quality Rules

- AI is opt-in.
- AI output is advisory.
- Default tests do not require network access.
- Generated Go from the normal transpiler must be reproducible.
- AI suggestions must include a visible review warning.
- Do not send proprietary code to a remote provider unless the user explicitly opts in.
- Store model name, prompt version, and timestamp in AI reports.
- Keep deterministic diagnostics strong enough that the project remains useful without AI.

## Implementation Order

1. Add structured diagnostics for unsupported Java features.
2. Add `--report` that emits deterministic Markdown and JSON.
3. Add fixture coverage for unsupported features.
4. Add `docs/ai-prompts.md` with prompt templates.
5. Add an offline AI provider that reads canned responses for tests.
6. Add an optional script or CLI flag for real AI suggestions.
7. Add `--ai-suggest` only after diagnostics and reports are stable.

This approach gets practical value from AI while preserving the compiler discipline needed for a real transpiler.
