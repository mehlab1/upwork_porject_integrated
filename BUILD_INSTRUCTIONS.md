# Building Release AAB for Android

This guide explains how to build a signed Android App Bundle (AAB) in release mode.

## Prerequisites

1. **Java JDK** installed (for keytool command)
2. **Flutter SDK** installed and configured
3. **Android SDK** installed

## Step 1: Create a Keystore (If you don't have one)

If you don't have a keystore file yet, create one using the following command:

```bash
keytool -genkey -v -keystore android/app/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

**Important Notes:**
- When prompted, use:
  - **Key password**: `abc123456` (or update `android/key.properties` with your password)
  - **Keystore password**: `abc123456` (or update `android/key.properties` with your password)
  - **Alias**: `upload` (must match the alias in `key.properties`)
- **Keep this keystore file safe!** You'll need it for all future app updates on Google Play Store.
- The keystore file should be placed at: `android/app/upload-keystore.jks`

## Step 2: Verify Configuration

The signing configuration is already set up in:
- `android/key.properties` - Contains keystore credentials
- `android/app/build.gradle.kts` - Configured to use the keystore for release builds

**Current settings in `key.properties`:**
- storePassword: abc123456
- keyPassword: abc123456
- keyAlias: upload
- storeFile: app/upload-keystore.jks

**If you used different passwords**, update `android/key.properties` accordingly.

## Step 3: Build the Release AAB

Run the following command from the project root:

```bash
flutter build appbundle --release
```

This will:
- Build the app in release mode (optimized, no debug symbols)
- Sign the AAB with your keystore
- Generate the file at: `build/app/outputs/bundle/release/app-release.aab`

## Step 4: Verify the Build

After building, you can verify the AAB was signed correctly:

```bash
jarsigner -verify -verbose -certs build/app/outputs/bundle/release/app-release.aab
```

## Alternative: Build APK (for testing)

If you want to build a signed APK instead (for testing, not for Play Store):

```bash
flutter build apk --release
```

The APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Troubleshooting

### Error: "Keystore file not found"
- Make sure `upload-keystore.jks` exists in `android/app/` directory
- Check the path in `android/key.properties` is correct: `app/upload-keystore.jks`

### Error: "Wrong password"
- Verify the passwords in `android/key.properties` match your keystore
- Make sure there are no extra spaces in `key.properties`

### Error: "Key alias not found"
- Ensure the alias in `key.properties` matches the alias used when creating the keystore
- Default alias should be: `upload`

## Security Note

⚠️ **IMPORTANT**: The `key.properties` file contains sensitive information. Make sure to:
- Add `android/key.properties` to `.gitignore` (if not already there)
- Never commit the keystore file (`upload-keystore.jks`) to version control
- Keep backups of your keystore in a secure location

