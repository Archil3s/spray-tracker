param(
  [string]$ApkPath = "",
  [switch]$Reinstall
)

$ErrorActionPreference = "Stop"

function Write-Step($message) {
  Write-Host "\n==> $message" -ForegroundColor Cyan
}

function Write-Problem($message) {
  Write-Host "\nERROR: $message" -ForegroundColor Red
}

function Find-Apk {
  param([string]$ProvidedPath)

  if ($ProvidedPath -and (Test-Path $ProvidedPath)) {
    return (Resolve-Path $ProvidedPath).Path
  }

  $candidates = @(
    ".\app-debug.apk",
    ".\build\app\outputs\flutter-apk\app-debug.apk",
    "$env:USERPROFILE\Downloads\app-debug.apk",
    "$env:USERPROFILE\Downloads\spray-tracker-debug-apk\app-debug.apk"
  )

  foreach ($candidate in $candidates) {
    if (Test-Path $candidate) {
      return (Resolve-Path $candidate).Path
    }
  }

  return $null
}

Write-Step "Checking for adb"
$adb = Get-Command adb -ErrorAction SilentlyContinue

if (-not $adb) {
  Write-Problem "adb was not found. Install Android Platform Tools first."
  Write-Host "\nOption 1: Android Studio > SDK Manager > Android SDK Platform-Tools"
  Write-Host "Option 2: Install platform tools and add adb.exe to PATH"
  Write-Host "\nAfter installing, close and reopen PowerShell, then run this script again."
  exit 1
}

Write-Host "adb found at: $($adb.Source)"

Write-Step "Finding APK"
$resolvedApk = Find-Apk -ProvidedPath $ApkPath

if (-not $resolvedApk) {
  Write-Problem "Could not find app-debug.apk."
  Write-Host "\nPlace app-debug.apk in one of these locations:"
  Write-Host "- Current folder"
  Write-Host "- $env:USERPROFILE\Downloads"
  Write-Host "- .\build\app\outputs\flutter-apk\app-debug.apk"
  Write-Host "\nOr run:"
  Write-Host ".\scripts\install-apk.ps1 -ApkPath C:\path\to\app-debug.apk"
  exit 1
}

Write-Host "APK: $resolvedApk"

Write-Step "Checking connected Android devices"
$devicesOutput = adb devices
$deviceLines = $devicesOutput | Where-Object { $_ -match "\tdevice$" }

if (-not $deviceLines -or $deviceLines.Count -eq 0) {
  Write-Problem "No authorized Android device found."
  Write-Host "\nOn your Galaxy A16:"
  Write-Host "1. Enable Developer options"
  Write-Host "2. Enable USB debugging"
  Write-Host "3. Reconnect USB cable"
  Write-Host "4. Accept the RSA debugging prompt on the phone"
  Write-Host "\nThen run this script again."
  Write-Host "\nadb devices output:"
  Write-Host $devicesOutput
  exit 1
}

Write-Host "Connected device(s):"
Write-Host $deviceLines

if ($Reinstall) {
  Write-Step "Removing previous debug install if present"
  adb uninstall com.example.spray_tracker | Out-Null
}

Write-Step "Installing APK"
adb install -r "$resolvedApk"

Write-Step "Install complete"
Write-Host "Open Spray Tracker on your Galaxy A16."
