$ErrorActionPreference = "Stop"

function Resolve-Tool {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Names,
        [Parameter(Mandatory = $true)]
        [string] $InstallHint
    )

    foreach ($Name in $Names) {
        $Command = Get-Command $Name -ErrorAction SilentlyContinue
        if ($Command) {
            return $Command.Source
        }
    }

    throw "Missing tool: $($Names -join ' or '). $InstallHint"
}

function Invoke-NativeChecked {
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

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = Join-Path $Root "build"
New-Item -ItemType Directory -Force $BuildDir | Out-Null

# Accept both GNU names and WinFlexBison shim names so the same script works
# with MSYS-style installs and Scoop/Chocolatey installs on Windows.
$Bison = Resolve-Tool -Names @("bison", "win_bison") -InstallHint "Install with: scoop install winflexbison"
$Flex = Resolve-Tool -Names @("flex", "win_flex") -InstallHint "Install with: scoop install winflexbison"
$Gxx = Resolve-Tool -Names @("g++") -InstallHint "Install GCC or use the existing Scoop GCC package."

# Bison generates parser.cpp plus parser.hpp; Flex includes that generated header.
Invoke-NativeChecked { & $Bison -d -o (Join-Path $BuildDir "parser.cpp") (Join-Path $Root "src\parser.y") } "bison"
Invoke-NativeChecked { & $Flex -o (Join-Path $BuildDir "lexer.cpp") (Join-Path $Root "src\lexer.l") } "flex"

Invoke-NativeChecked { & $Gxx `
    -std=c++17 `
    "-I$($Root)\src" `
    "-I$BuildDir" `
    (Join-Path $BuildDir "parser.cpp") `
    (Join-Path $BuildDir "lexer.cpp") `
    (Join-Path $Root "src\ast.cpp") `
    (Join-Path $Root "src\diagnostics.cpp") `
    (Join-Path $Root "src\generator.cpp") `
    (Join-Path $Root "src\main.cpp") `
    -o (Join-Path $BuildDir "javago.exe") } "g++"

Write-Host "Built $BuildDir\javago.exe"
