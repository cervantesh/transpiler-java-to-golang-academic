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

$Cases = @(
    "hello_print",
    "variables",
    "if_else",
    "while_loop",
    "method_return"
)

foreach ($Case in $Cases) {
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
    @{ Name = "unsupported_overload"; Code = "JTG1018"; Feature = "method overloading" }
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
