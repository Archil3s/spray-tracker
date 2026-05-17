# Windows PowerShell APK auto-install

This project includes a PowerShell script for installing the debug APK directly onto a connected Android phone using `adb`.

## Requirements

- Windows PC
- Samsung Galaxy A16 connected by USB
- USB debugging enabled on the phone
- Android Platform Tools installed so `adb` is available in PowerShell
- `app-debug.apk` downloaded from GitHub Actions or built locally

## Enable USB debugging on Galaxy A16

1. Open **Settings**.
2. Go to **About phone**.
3. Open **Software information**.
4. Tap **Build number** 7 times.
5. Go back to **Settings**.
6. Open **Developer options**.
7. Enable **USB debugging**.
8. Connect the phone to the PC.
9. Accept the RSA debugging prompt on the phone.

## Install Android Platform Tools

Install `adb` using either Android Studio or standalone Platform Tools.

After installing, make sure `adb` works in PowerShell:

```powershell
adb devices
```

You should see your phone listed as `device`.

## Basic install

Put `app-debug.apk` in your Downloads folder, then run from the repo root:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-apk.ps1
```

## Install from a specific APK path

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-apk.ps1 -ApkPath "C:\Users\YOURNAME\Downloads\app-debug.apk"
```

## Reinstall cleanly

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-apk.ps1 -ApkPath "C:\Users\YOURNAME\Downloads\app-debug.apk" -Reinstall
```

## What the script does

- Checks that `adb` is installed
- Finds `app-debug.apk`
- Checks that the phone is connected and authorized
- Installs the APK using:

```powershell
adb install -r app-debug.apk
```

## Troubleshooting

### Device shows as unauthorized

Unlock the phone and accept the USB debugging prompt.

### No device found

Try:

```powershell
adb kill-server
adb start-server
adb devices
```

Then reconnect the USB cable.

### Windows cannot run the script

Use:

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\install-apk.ps1
```
