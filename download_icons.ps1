# PowerShell script to download animated icons for various UI elements

# Define the icons to download
$icons = @(
    # Social Media (existing)
    @{ Name = "facebook"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/34517-facebook-icon-animate.json" },
    @{ Name = "instagram"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/39616-instagram-icon.json" },
    @{ Name = "twitter"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/49409-twitter-icon.json" },
    @{ Name = "linkedin"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/41141-linkedin-icon-2020.json" },
    @{ Name = "youtube"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/43570-youtube-icon.json" },
    @{ Name = "telegram"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/49415-telegram-icon.json" },
    @{ Name = "tiktok"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/49416-tiktok-icon.json" },
    @{ Name = "whatsapp"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/45283-whatsapp-3d-icon.json" },
    @{ Name = "pinterest"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/74295-pinterest-icon.json" },
    @{ Name = "github"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/6879-linkedin-social-media-icon.json" },

    # UI Elements (new)
    @{ Name = "about"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/37056-community-icon.json" },
    @{ Name = "test_type"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/35728-calendar-icon.json" },
    @{ Name = "notifications"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/33262-icons-bell-notification.json" },
    @{ Name = "theme"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/36236-sun-icon.json" },
    @{ Name = "language"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/34693-google-icons-translate.json" },
    @{ Name = "power"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/34311-hamburger-icon.json" },
    @{ Name = "info"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/51955-info-icon-animated.json" },
    @{ Name = "update"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/36015-shopping.json" },
    @{ Name = "support"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/37058-start-icon.json" },
    @{ Name = "dns"; Url = "https://raw.githubusercontent.com/iconforest/flutter_animated_icons/main/assets/lottiefiles.com/34651-shield-icon.json" }
)

# Directory to save icons
$dir = "D:\project\FireDNS\firedns\assets\icone"

# Create directory if not exists
if (!(Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir
}

# Download each icon
foreach ($icon in $icons) {
    $outputPath = Join-Path $dir "$($icon.Name).json"
    Write-Host "Downloading $($icon.Name) from $($icon.Url) to $outputPath"
    try {
        Invoke-WebRequest -Uri $icon.Url -OutFile $outputPath
        Write-Host "Downloaded $($icon.Name) successfully"
    } catch {
        Write-Host "Failed to download $($icon.Name): $($_.Exception.Message)"
    }
}

Write-Host "All downloads completed."
