# PowerShell script to download Noto Nastaliq Urdu fonts
$fontFiles = @{
    "Regular" = "https://github.com/google/fonts/raw/main/ofl/notonastaliqurdu/NotoNastaliqUrdu-Regular.ttf"
    "Bold" = "https://github.com/google/fonts/raw/main/ofl/notonastaliqurdu/NotoNastaliqUrdu-Bold.ttf"
}

$outputDir = "assets/fonts"

Write-Host "Downloading Noto Nastaliq Urdu font files to $outputDir..."
foreach ($font in $fontFiles.Keys) {
    $url = $fontFiles[$font]
    $outputFile = "$outputDir/NotoNastaliqUrdu-$font.ttf"
    Write-Host "Downloading NotoNastaliqUrdu-$font.ttf..."
    Invoke-WebRequest -Uri $url -OutFile $outputFile
    if (Test-Path $outputFile) {
        Write-Host "Successfully downloaded NotoNastaliqUrdu-$font.ttf"
    } else {
        Write-Host "Failed to download NotoNastaliqUrdu-$font.ttf"
    }
}

Write-Host "Font download process completed." 