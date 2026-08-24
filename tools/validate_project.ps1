param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$resolvedRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$errors = [System.Collections.Generic.List[string]]::new()
$checkedReferences = 0

function Add-ValidationError {
    param([string]$Message)
    $errors.Add($Message)
}

function Test-GdscriptDelimiters {
    param([string]$Path)

    $text = Get-Content -Raw -LiteralPath $Path
    $stack = [System.Collections.Generic.Stack[char]]::new()
    $inString = $false
    $escaped = $false
    $inComment = $false
    $line = 1
    $pairs = @{ ')' = '('; ']' = '['; '}' = '{' }

    foreach ($character in $text.ToCharArray()) {
        if ($character -eq "`n") {
            $line++
            $inComment = $false
            $escaped = $false
            continue
        }
        if ($inComment) {
            continue
        }
        if ($inString) {
            if ($escaped) {
                $escaped = $false
            }
            elseif ($character -eq '\') {
                $escaped = $true
            }
            elseif ($character -eq '"') {
                $inString = $false
            }
            continue
        }
        if ($character -eq '#') {
            $inComment = $true
            continue
        }
        if ($character -eq '"') {
            $inString = $true
            continue
        }
        if ($character -in @('(', '[', '{')) {
            $stack.Push($character)
            continue
        }
        if ($character -in @(')', ']', '}')) {
            if ($stack.Count -eq 0 -or $stack.Pop() -ne $pairs[[string]$character]) {
                Add-ValidationError "Delimiter mismatch in $Path near line $line"
                return
            }
        }
    }

    if ($inString) {
        Add-ValidationError "Unterminated string in $Path"
    }
    if ($stack.Count -gt 0) {
        Add-ValidationError "Unclosed delimiter in $Path"
    }
}

$requiredFiles = @(
    'project.godot',
    'scenes/main.tscn',
    'scripts/main.gd',
    'scripts/audio/audio_manager.gd',
    'scripts/autoload/game_state.gd',
    'scripts/entities/player.gd',
    'scripts/entities/spirit_beast.gd',
    'scripts/entities/companion.gd',
    'scripts/entities/mentor.gd',
    'scripts/combat/seal_projectile.gd',
    'scripts/combat/enemy_projectile.gd',
    'scripts/ui/hud.gd',
    'scripts/world/world_arena.gd',
    'assets/third_party/kenney/rpg_audio/LICENSE.txt',
    'assets/third_party/kenney/fantasy_ui_borders/LICENSE.txt',
    'assets/third_party/opengameart/magic_spell_sfx/LICENSE.md',
    'tests/test_runner.gd',
    'tests/test_runner.tscn',
    'tests/integration_runner.gd',
    'tests/integration_runner.tscn'
)

foreach ($relativePath in $requiredFiles) {
    $fullPath = Join-Path $resolvedRoot $relativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-ValidationError "Missing required file: $relativePath"
    }
}

$sourceFiles = Get-ChildItem -LiteralPath $resolvedRoot -Recurse -File |
    Where-Object { $_.Extension -in @('.gd', '.tscn', '.godot') -or $_.Name -eq 'project.godot' }

foreach ($sourceFile in $sourceFiles) {
    $content = Get-Content -Raw -LiteralPath $sourceFile.FullName
    foreach ($match in [regex]::Matches($content, 'res://([^"'')]+)')) {
        $resourcePath = $match.Groups[1].Value.Replace('/', [IO.Path]::DirectorySeparatorChar)
        $resourceFullPath = Join-Path $resolvedRoot $resourcePath
        $checkedReferences++
        if (-not (Test-Path -LiteralPath $resourceFullPath -PathType Leaf)) {
            Add-ValidationError "Broken resource reference in $($sourceFile.FullName): res://$($match.Groups[1].Value)"
        }
    }
}

$gdscriptFiles = Get-ChildItem -LiteralPath (Join-Path $resolvedRoot 'scripts') -Recurse -Filter '*.gd' -File
foreach ($script in $gdscriptFiles) {
    Test-GdscriptDelimiters -Path $script.FullName
    $lineNumber = 0
    foreach ($line in Get-Content -LiteralPath $script.FullName) {
        $lineNumber++
        if ($line -match '^ +\S') {
            Add-ValidationError "Space indentation in $($script.FullName):$lineNumber (GDScript project convention requires tabs)"
        }
    }
}

try {
    [xml](Get-Content -Raw -LiteralPath (Join-Path $resolvedRoot 'icon.svg')) | Out-Null
}
catch {
    Add-ValidationError "icon.svg is not valid XML: $($_.Exception.Message)"
}

$projectContent = Get-Content -Raw -LiteralPath (Join-Path $resolvedRoot 'project.godot')
if ($projectContent -notmatch 'run/main_scene="res://scenes/main.tscn"') {
    Add-ValidationError 'project.godot does not point to scenes/main.tscn'
}
if ($projectContent -notmatch 'GameState="\*res://scripts/autoload/game_state.gd"') {
    Add-ValidationError 'GameState autoload is missing'
}

if ($errors.Count -gt 0) {
    Write-Host "Static validation failed with $($errors.Count) error(s):" -ForegroundColor Red
    foreach ($validationError in $errors) {
        Write-Host " - $validationError" -ForegroundColor Red
    }
    exit 1
}

Write-Host "Static validation passed: $($gdscriptFiles.Count) GDScript files, $checkedReferences resource references, SVG XML valid." -ForegroundColor Green
Write-Host 'Note: this does not replace Godot parser or runtime validation.' -ForegroundColor Yellow
