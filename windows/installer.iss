#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppId=U310BodyCompositionReport
AppName=U310 Body Composition Report
AppVersion={#AppVersion}
DefaultDirName={localappdata}\Programs\U310
DefaultGroupName=U310
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
OutputDir=..\build\installer
OutputBaseFilename=U310-Setup-{#AppVersion}-x64
SetupIconFile=runner\resources\app_icon.ico
UninstallDisplayIcon={app}\u310_app.exe
Compression=lzma
SolidCompression=yes
WizardStyle=modern

[Files]
Source: "..\build\windows\x64\runner\Release\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked

[Icons]
Name: "{autoprograms}\U310"; Filename: "{app}\u310_app.exe"
Name: "{autodesktop}\U310"; Filename: "{app}\u310_app.exe"; Tasks: desktopicon

[Run]
Filename: "{app}\u310_app.exe"; Description: "Launch U310"; Flags: nowait postinstall skipifsilent
