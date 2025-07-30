from PIL import Image
import os
import shutil
import json

def create_directory_if_not_exists(path):
    if not os.path.exists(path):
        os.makedirs(path)

def update_json_file(file_path, content):
    create_directory_if_not_exists(os.path.dirname(file_path))
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(content, f, indent=2)

def generate_ios_json():
    contents = {
        "images": [
            {
                "size": "20x20",
                "idiom": "iphone",
                "filename": "Icon-App-20x20@2x.png",
                "scale": "2x"
            },
            {
                "size": "20x20",
                "idiom": "iphone",
                "filename": "Icon-App-20x20@3x.png",
                "scale": "3x"
            },
            # ... سایر سایزها برای iPhone
            {
                "size": "1024x1024",
                "idiom": "ios-marketing",
                "filename": "Icon-App-1024x1024@1x.png",
                "scale": "1x"
            }
        ],
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }
    update_json_file('ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json', contents)

def generate_macos_json():
    contents = {
        "images": [
            {
                "size": "16x16",
                "idiom": "mac",
                "filename": "app_icon_16.png",
                "scale": "1x"
            },
            # ... سایر سایزها برای macOS
        ],
        "info": {
            "version": 1,
            "author": "xcode"
        }
    }
    update_json_file('macos/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json', contents)

def update_web_manifest():
    manifest_path = 'web/manifest.json'
    if os.path.exists(manifest_path):
        with open(manifest_path, 'r', encoding='utf-8') as f:
            manifest = json.load(f)
        
        manifest['icons'] = [
            {
                "src": "icons/Icon-192.png",
                "sizes": "192x192",
                "type": "image/png"
            },
            {
                "src": "icons/Icon-512.png",
                "sizes": "512x512",
                "type": "image/png"
            },
            {
                "src": "icons/Icon-maskable-192.png",
                "sizes": "192x192",
                "type": "image/png",
                "purpose": "maskable"
            },
            {
                "src": "icons/Icon-maskable-512.png",
                "sizes": "512x512",
                "type": "image/png",
                "purpose": "maskable"
            }
        ]
        update_json_file(manifest_path, manifest)

def create_linux_desktop():
    desktop_content = """[Desktop Entry]
Name=FireDNS
Comment=FireDNS Application
Exec=firedns
Icon=${SNAP}/meta/gui/icon.png
Terminal=false
Type=Application
Categories=Utility;
"""
    desktop_path = 'linux/firedns.desktop'
    create_directory_if_not_exists(os.path.dirname(desktop_path))
    with open(desktop_path, 'w', encoding='utf-8') as f:
        f.write(desktop_content)

# مسیر فایل لوگوی اصلی
logo_path = r"assets/logo/logo2.png"

# تنظیمات آیکون‌های اندروید
android_icons = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192
}

# تنظیمات آیکون‌های iOS
ios_icons = {
    '20x20': 20,
    '29x29': 29,
    '40x40': 40,
    '60x60': 60,
    '76x76': 76,
    '83.5x83.5': 84,
    '1024x1024': 1024
}

# تنظیمات آیکون‌های وب
web_icons = {
    'favicon.png': 16,
    'icons/Icon-192.png': 192,
    'icons/Icon-512.png': 512,
    'icons/Icon-maskable-192.png': 192,
    'icons/Icon-maskable-512.png': 512
}

# تنظیمات آیکون‌های ویندوز
windows_icons = {
    'app_icon.ico': 256,
    'resources/app_icon.ico': 256
}

# تنظیمات آیکون‌های مک
macos_icons = {
    'app.icns': 512,
    'AppIcon.iconset/icon_16x16.png': 16,
    'AppIcon.iconset/icon_32x32.png': 32,
    'AppIcon.iconset/icon_64x64.png': 64,
    'AppIcon.iconset/icon_128x128.png': 128,
    'AppIcon.iconset/icon_256x256.png': 256,
    'AppIcon.iconset/icon_512x512.png': 512,
    'AppIcon.iconset/icon_1024x1024.png': 1024
}

# تنظیمات آیکون‌های لینوکس
linux_icons = {
    '16x16': 16,
    '32x32': 32,
    '48x48': 48,
    '64x64': 64,
    '128x128': 128,
    '256x256': 256
}

android_res_path = os.path.join('android', 'app', 'src', 'main', 'res')

# بارگذاری لوگو
logo = Image.open(logo_path)

def save_resized_image(image, size, output_path):
    if not os.path.exists(os.path.dirname(output_path)):
        os.makedirs(os.path.dirname(output_path))
    resized = image.resize((size, size), Image.LANCZOS)
    resized.save(output_path)
    print(f"Saved: {output_path}")

# ساخت آیکون‌های اندروید
print("\nGenerating Android icons...")
for folder, size in android_icons.items():
    out_dir = os.path.join(android_res_path, folder)
    out_path = os.path.join(out_dir, 'ic_launcher.png')
    save_resized_image(logo, size, out_path)

# ساخت آیکون‌های iOS
print("\nGenerating iOS icons...")
ios_asset_path = os.path.join('ios', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
for name, size in ios_icons.items():
    out_path = os.path.join(ios_asset_path, f'Icon-{name}.png')
    save_resized_image(logo, size, out_path)

# ساخت آیکون‌های وب
print("\nGenerating Web icons...")
web_path = 'web'
for name, size in web_icons.items():
    out_path = os.path.join(web_path, name)
    save_resized_image(logo, size, out_path)

# ساخت آیکون‌های ویندوز
print("\nGenerating Windows icons...")
windows_path = 'windows/runner'
for name, size in windows_icons.items():
    out_path = os.path.join(windows_path, name)
    save_resized_image(logo, size, out_path)

def create_icns():
    print("\nGenerating macOS .icns file...")
    macos_path = os.path.join('macos', 'Runner', 'Assets.xcassets', 'AppIcon.appiconset')
    iconset_path = os.path.join(macos_path, 'AppIcon.iconset')
    
    if not os.path.exists(iconset_path):
        os.makedirs(iconset_path)
    
    # ساخت همه سایزهای مورد نیاز
    for name, size in macos_icons.items():
        if 'iconset' in name:  # فقط فایل‌های داخل iconset
            out_path = os.path.join(macos_path, name)
            save_resized_image(logo, size, out_path)
    
    # تبدیل iconset به icns
    if os.system('which iconutil') == 0:  # فقط در مک‌او‌اس
        os.system(f'iconutil -c icns {iconset_path} -o {os.path.join(macos_path, "AppIcon.icns")}')
    else:
        print("Warning: iconutil not found. .icns file could not be created. This is normal if you're not on macOS.")

# ساخت آیکون‌های لینوکس
print("\nGenerating Linux icons...")
linux_path = os.path.join('linux', 'icons')
for name, size in linux_icons.items():
    out_path = os.path.join(linux_path, f'app-{name}.png')
    save_resized_image(logo, size, out_path)

# به‌روزرسانی فایل‌های پیکربندی
print("\nUpdating configuration files...")
generate_ios_json()
generate_macos_json()
update_web_manifest()
create_linux_desktop()

print("\nتمام آیکون‌ها و فایل‌های پیکربندی برای همه پلتفرم‌ها به‌روز شدند.")
