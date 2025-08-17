$fonts = @(
    "Regular",
    "Medium",
    "SemiBold",
    "Bold",
    "Light",
    "Black",
    "ExtraBold",
    "Thin"
)

foreach ($weight in $fonts) {
    $url = "https://github.com/google/fonts/raw/main/ofl/poppins/Poppins-$weight.ttf"
    $outFile = "Poppins-$weight.ttf"
    Invoke-WebRequest -Uri $url -OutFile $outFile
}
