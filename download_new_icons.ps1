# Download new animated icons for better alternatives
$baseUrl = 'https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/icons'

# New icons to try downloading
$icons = @(
    @{Name='github_2'; Url="$baseUrl/github_2.json"},
    @{Name='settings_2'; Url="$baseUrl/settings_2.json"},
    @{Name='speedometer'; Url="$baseUrl/speedometer.json"},
    @{Name='web'; Url="$baseUrl/web.json"},
    @{Name='internet'; Url="$baseUrl/internet.json"},
    @{Name='network'; Url="$baseUrl/network.json"},
    @{Name='computer'; Url="$baseUrl/computer.json"}
)

foreach ($icon in $icons) {
    try {
        $outputPath = "assets/icone/$($icon.Name).json"
        Write-Host "Downloading $($icon.Name).json..."
        Invoke-WebRequest -Uri $icon.Url -OutFile $outputPath -TimeoutSec 15
        if (Test-Path $outputPath) {
            $fileSize = (Get-Item $outputPath).Length
            if ($fileSize -gt 1000) {
                Write-Host "Downloaded $($icon.Name).json ($fileSize bytes)"
            } else {
                Remove-Item $outputPath -Force
                Write-Host "Downloaded $($icon.Name).json but file is too small, deleted"
            }
        } else {
            Write-Host "Failed to download $($icon.Name).json"
        }
    } catch {
        Write-Host "Failed to download $($icon.Name).json - $($_.Exception.Message)"
    }
}

Write-Host "Icon download process completed!"
