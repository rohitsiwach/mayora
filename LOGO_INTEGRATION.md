# Logo Integration Guide

This document explains how to properly integrate your custom logo into the Mayora app.

## Steps to Replace Logo Placeholders

1. **Prepare your logo files**:
   - Create three versions of your logo:
     - `mayora_logo.png` (120x120 pixels) - Main logo
     - `mayora_logo_small.png` (64x64 pixels) - Small version
     - `mayora_logo_large.png` (256x256 pixels) - Large version

2. **Replace the placeholder files**:
   - Navigate to `assets/images/` directory
   - Replace the existing placeholder files with your actual logo images
   - Maintain the same file names

3. **Logo appears in these locations**:
   - **Splash Screen**: Large animated logo with fade and scale effects
   - **App Bar**: Small logo next to the app title
   - **Home Screen**: Medium-sized logo in the center with gradient background
   - **About Page**: Large logo with detailed app information
   - **Navigation Drawer**: Logo in the drawer header with gradient background

## Logo Requirements

- **Format**: PNG with transparent background recommended
- **Aspect Ratio**: Square (1:1) works best
- **Colors**: The current color scheme uses purple gradients (#673AB7, #9C27B0, #00BCD4)
- **Style**: The swirl gradient design shown in your reference image

## Testing After Logo Replacement

After replacing the logo files, run these commands to test:

```bash
# Get dependencies
flutter pub get

# Run tests
flutter test

# Run the app
flutter run
```

## Web Icons

For web deployment, you may also want to replace:
- `web/favicon.png`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`

## Android Icons

For Android app icons, you can use tools like:
- Android Studio's Image Asset Studio
- Online icon generators
- Replace files in `android/app/src/main/res/mipmap-*` directories

## iOS Icons

For iOS app icons, replace files in:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`

Note: iOS requires multiple icon sizes for different device types and contexts.