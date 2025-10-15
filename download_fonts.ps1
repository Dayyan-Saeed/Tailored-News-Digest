$fontFiles = @{
    "Regular" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Regular.ttf"
    "Medium" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Medium.ttf"
    "SemiBold" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-SemiBold.ttf"
    "Bold" = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-Bold.ttf"
}

$outputDir = "assets/fonts"

Write-Host "Downloading Poppins font files to $outputDir..."
foreach ($font in $fontFiles.Keys) {
    $url = $fontFiles[$font]
    $outputFile = "$outputDir/Poppins-$font.ttf"
    Write-Host "Downloading Poppins-$font.ttf..."
    Invoke-WebRequest -Uri $url -OutFile $outputFile
    if (Test-Path $outputFile) {
        Write-Host "Successfully downloaded Poppins-$font.ttf"
    } else {
        Write-Host "Failed to download Poppins-$font.ttf"
    }
}

Write-Host "Font download process completed." 