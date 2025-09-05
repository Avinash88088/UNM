# App Logo Files

## Required Files:

1. **app_icon.png** (1024x1024 pixels)
   - High resolution logo file
   - This will be used to generate all other sizes

## How to Use:

1. **Add your logo file:**
   - Copy your logo file to this folder
   - Name it `app_icon.png`
   - Make sure it's 1024x1024 pixels

2. **Generate app icons:**
   ```bash
   flutter pub get
   flutter pub run flutter_launcher_icons:main
   ```

3. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

## Logo Requirements:

- **Format:** PNG
- **Size:** 1024x1024 pixels
- **Background:** Transparent or solid color
- **Quality:** High resolution, clear and sharp

## Supported Platforms:

- ✅ Android
- ✅ iOS  
- ✅ Web
- ✅ Windows
- ✅ macOS

## Note:

After adding your logo file, run the command:
`flutter pub run flutter_launcher_icons:main`

This will automatically generate all required icon sizes for all platforms.
