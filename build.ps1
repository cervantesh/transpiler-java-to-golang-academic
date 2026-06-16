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

$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = Join-Path $Root "build"
New-Item -ItemType Directory -Force $BuildDir | Out-Null

$Bison = Resolve-Tool -Names @("bison", "win_bison") -InstallHint "Install with: scoop install winflexbison"
$Flex = Resolve-Tool -Names @("flex", "win_flex") -InstallHint "Install with: scoop install winflexbison"
$Gxx = Resolve-Tool -Names @("g++") -InstallHint "Install GCC or use the existing Scoop GCC package."

& $Bison -d -o (Join-Path $BuildDir "parser.cpp") (Join-Path $Root "src\parser.y")
& $Flex -o (Join-Path $BuildDir "lexer.cpp") (Join-Path $Root "src\lexer.l")

& $Gxx `
    -std=c++17 `
    "-I$($Root)\src" `
    "-I$BuildDir" `
    (Join-Path $BuildDir "parser.cpp") `
    (Join-Path $BuildDir "lexer.cpp") `
    (Join-Path $Root "src\ast.cpp") `
    (Join-Path $Root "src\diagnostics.cpp") `
    (Join-Path $Root "src\generator.cpp") `
    (Join-Path $Root "src\main.cpp") `
    -o (Join-Path $BuildDir "javago.exe")

Write-Host "Built $BuildDir\javago.exe"
