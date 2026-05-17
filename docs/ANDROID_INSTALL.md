# Android APK install instructions

This project can build a debug APK through GitHub Actions.

## Build the APK

1. Open the repository on GitHub.
2. Go to **Actions**.
3. Select **Build Android APK**.
4. Click **Run workflow**.
5. Wait for the workflow to finish.
6. Open the completed workflow run.
7. Download the artifact named **spray-tracker-debug-apk**.
8. Extract the downloaded ZIP file.
9. The APK file will be named:

```text
app-debug.apk
```

## Copy to Samsung Galaxy A16

With the phone connected to Windows:

```text
This PC\Galaxy A16\Internal storage\Download
```

Copy `app-debug.apk` into that folder.

## Install on the phone

1. On the phone, open **My Files**.
2. Open **Internal storage**.
3. Open **Download**.
4. Tap `app-debug.apk`.
5. Approve install from unknown apps if Android asks.
6. Tap **Install**.

## Notes

- This is a debug APK for testing.
- Data is currently in-memory only and resets when the app restarts.
- Later, the app should use local persistence before regular testing builds.
