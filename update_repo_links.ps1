# Script to update repository links from 'miyolist' to 'miyolist-public'

Write-Host "🔗 Updating repository links..." -ForegroundColor Cyan

# Define the replacement
$oldRepo = 'Baconana-chan/miyolist'
$newRepo = 'Baconana-chan/miyolist-public'

# Get all relevant files
$files = Get-ChildItem -Path "." -Recurse -Include "*.md","*.dart" -Exclude "node_modules","build"

$filesModified = 0

foreach ($file in $files) {
    $content = Get-Content $file.FullName -Raw -ErrorAction SilentlyContinue
    
    if ($null -eq $content) { continue }
    
    if ($content -match [regex]::Escape($oldRepo)) {
        $content = $content -replace [regex]::Escape($oldRepo), $newRepo
        Set-Content -Path $file.FullName -Value $content -NoNewline
        Write-Host "✅ Updated: $($file.Name)" -ForegroundColor Green
        $filesModified++
    }
}

Write-Host "`n✨ Complete! Modified $filesModified files" -ForegroundColor Green
Write-Host "Repository links updated from '$oldRepo' to '$newRepo'" -ForegroundColor Cyan
