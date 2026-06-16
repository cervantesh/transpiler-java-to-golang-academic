$ErrorActionPreference = "Stop"

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$Exe = Join-Path $Root "build\javago.exe"
$GeneratedDir = Join-Path $Root "tests\generated"

function Invoke-Checked {
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock] $Command,
        [Parameter(Mandatory = $true)]
        [string] $Label
    )

    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit code $LASTEXITCODE"
    }
}

& (Join-Path $Root "build.ps1")
New-Item -ItemType Directory -Force $GeneratedDir | Out-Null

# Supported cases are golden tests: generated Go must match the expected file,
# pass gofmt, and execute successfully with go run.
$SupportedCases = @(
    "hello_print",
    "variables",
    "if_else",
    "while_loop",
    "method_return",
    "arithmetic_precedence",
    "parenthesized_expression",
    "unary_minus",
    "boolean_and_or",
    "boolean_not",
    "equality_inequality",
    "comparison_bounds",
    "string_variable",
    "double_arithmetic",
    "comments_handling",
    "no_fmt_import",
    "return_without_value",
    "static_void_method_call",
    "nested_control",
    "multiple_parameters"
)

foreach ($Case in $SupportedCases) {
    $InputPath = Join-Path $Root "tests\fixtures\$Case.java"
    $Actual = Join-Path $GeneratedDir "$Case.go"
    $Expected = Join-Path $Root "tests\expected\$Case.go"

    Invoke-Checked { & $Exe $InputPath $Actual } "transpile $Case"
    Invoke-Checked { gofmt -w $Actual } "gofmt $Case"

    $ActualText = Get-Content -Raw $Actual
    $ExpectedText = Get-Content -Raw $Expected
    if ($ActualText -ne $ExpectedText) {
        Write-Error "Golden test failed: $Case"
    }

    Invoke-Checked { & go run $Actual | Out-Null } "go run $Case"
    Write-Host "PASS $Case"
}

# Syntax errors and unsupported-feature cases must fail clearly and must not
# leave a generated Go file behind.
$SyntaxInput = Join-Path $Root "tests\fixtures\syntax_error.java"
$SyntaxOutput = Join-Path $GeneratedDir "syntax_error.go"
$ErrorFile = Join-Path $GeneratedDir "syntax_error.stderr.txt"

& $Exe $SyntaxInput $SyntaxOutput 2> $ErrorFile
if ($LASTEXITCODE -eq 0) {
    Write-Error "syntax_error.java unexpectedly succeeded"
}

$ErrorText = Get-Content -Raw $ErrorFile
if ($ErrorText -notmatch "line" -or $ErrorText -notmatch "column") {
    Write-Error "syntax_error.java did not report line and column"
}

Write-Host "PASS syntax_error"

$UnsupportedCases = @(
    @{ Name = "unsupported_field"; Code = "JTG1016"; Feature = "class fields" },
    @{ Name = "unsupported_package_import"; Code = "JTG1001"; Feature = "package declarations" },
    @{ Name = "unsupported_exception"; Code = "JTG1007"; Feature = "try/catch exceptions" },
    @{ Name = "unsupported_instance_method"; Code = "JTG1017"; Feature = "instance methods" },
    @{ Name = "unsupported_overload"; Code = "JTG1018"; Feature = "method overloading" },
    @{ Name = "unsupported_interface"; Code = "JTG1003"; Feature = "interfaces" },
    @{ Name = "unsupported_inheritance"; Code = "JTG1004"; Feature = "inheritance" },
    @{ Name = "unsupported_generics"; Code = "JTG1014"; Feature = "generics" },
    @{ Name = "unsupported_array_indexing"; Code = "JTG1015"; Feature = "arrays and indexing" }
)

foreach ($Case in $UnsupportedCases) {
    $InputPath = Join-Path $Root "tests\fixtures\$($Case.Name).java"
    $Actual = Join-Path $GeneratedDir "$($Case.Name).go"
    $ErrorFile = Join-Path $GeneratedDir "$($Case.Name).stderr.txt"

    Remove-Item -Force $Actual, $ErrorFile -ErrorAction SilentlyContinue

    & $Exe $InputPath $Actual 2> $ErrorFile
    if ($LASTEXITCODE -eq 0) {
        Write-Error "$($Case.Name).java unexpectedly succeeded"
    }
    if (Test-Path $Actual) {
        Write-Error "$($Case.Name).java wrote Go output despite unsupported diagnostics"
    }

    $ErrorText = Get-Content -Raw $ErrorFile
    if ($ErrorText -notmatch [regex]::Escape($Case.Code)) {
        Write-Error "$($Case.Name).java did not report diagnostic code $($Case.Code)"
    }
    if ($ErrorText -notmatch [regex]::Escape("unsupported feature: $($Case.Feature)")) {
        Write-Error "$($Case.Name).java did not report feature $($Case.Feature)"
    }
    if ($ErrorText -notmatch "recommendation:") {
        Write-Error "$($Case.Name).java did not include a recommendation"
    }

    Write-Host "PASS $($Case.Name)"
}

$TotalCases = $SupportedCases.Count + 1 + $UnsupportedCases.Count
if ($TotalCases -ne 30) {
    Write-Error "Expected exactly 30 evidence cases, got $TotalCases"
}

Write-Host "PASS evidence_case_count => $TotalCases"
