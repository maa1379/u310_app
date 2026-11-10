# U310 Body Composition Report

Flutter application for viewing U310 measurements on Web, Android, and Windows. The report is drawn with Flutter widgets and `CustomPainter`; the prototype HTML is not loaded by the app.

## Use

1. Open the app. No report is selected at startup.
2. Import a `.txt` or `.json` export. The app accepts JSON directly or Base64 encoded JSON with a `DataArray`.
3. Select a measurement from the local history. Each measurement in an imported file appears separately.
4. Use **Print** or **Save PDF**. The PDF is one A4 page made from the Flutter report.

History is stored locally on the device or browser. The synthetic sample file is used by tests and is not imported automatically.

## Build

```sh
flutter pub get
flutter run -d chrome
flutter build web --release
flutter build apk --debug
```

On a Windows machine with Flutter desktop support:

```powershell
flutter build windows --release
```

Every push also builds a Windows installer in GitHub Actions. Open the latest
**Build Windows installer** run and download the `U310-Windows-Installer`
artifact. Its ZIP contains `U310-Setup-<version>-x64.exe`, which installs the
complete app for the current Windows user.

## Verify

```sh
flutter test
dart analyze lib test
```
