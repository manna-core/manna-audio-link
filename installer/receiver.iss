#define AppName "Manna Sound Sync"
#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\dist\installer-staging\MannaAudioLink"
#endif
#ifndef OutputDir
  #define OutputDir "..\dist\installer"
#endif

[Setup]
AppId={{5A8F5B59-2F14-4C30-B23D-E785E0E71F31}
AppName={#AppName}
AppVersion={#AppVersion}
AppPublisher=Manna
AppPublisherURL=https://github.com/manna-core
AppSupportURL=https://github.com/manna-core/manna-audio-link
AppUpdatesURL=https://github.com/manna-core/manna-audio-link/releases
DefaultDirName={localappdata}\Programs\{#AppName}
DefaultGroupName={#AppName}
AllowNoIcons=yes
DisableWelcomePage=no
DisableDirPage=no
DisableProgramGroupPage=yes
OutputDir={#OutputDir}
OutputBaseFilename=MannaSoundSync-{#AppVersion}-Receiver-Setup
Compression=lzma
SolidCompression=yes
WizardStyle=modern
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\assets\icons\manna-audio-link.ico
SetupIconFile=..\assets\icons\manna-audio-link.ico

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "Create a desktop shortcut"; GroupDescription: "Additional shortcuts:"; Flags: unchecked

[Files]
Source: "{#SourceDir}\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "MannaSoundSync"; ValueData: """{sys}\WindowsPowerShell\v1.0\powershell.exe"" -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\launch-manna-sound-sync.ps1"""; Flags: uninsdeletevalue; Check: StartOnBootSelected

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\launch-manna-sound-sync.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\assets\icons\manna-audio-link.ico"
Name: "{autodesktop}\{#AppName}"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\launch-manna-sound-sync.ps1"""; WorkingDir: "{app}"; Tasks: desktopicon; IconFilename: "{app}\assets\icons\manna-audio-link.ico"

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File ""{app}\launch-manna-sound-sync.ps1"""; WorkingDir: "{app}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent unchecked
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -NoExit -File ""{app}\show-local-ip.ps1"""; WorkingDir: "{app}"; Description: "Show this main PC's IP for the laptop sender"; Flags: nowait postinstall skipifsilent

[Code]
var
  StartOnBootCheckBox: TNewCheckBox;

function StartOnBootSelected: Boolean;
begin
  Result := Assigned(StartOnBootCheckBox) and StartOnBootCheckBox.Checked;
end;

procedure InitializeWizard;
begin
  StartOnBootCheckBox := TNewCheckBox.Create(WizardForm);
  StartOnBootCheckBox.Parent := WizardForm.WelcomePage;
  StartOnBootCheckBox.Left := WizardForm.WelcomeLabel2.Left;
  StartOnBootCheckBox.Top := WizardForm.WelcomeLabel2.Top + WizardForm.WelcomeLabel2.Height + ScaleY(18);
  StartOnBootCheckBox.Width := WizardForm.WelcomeLabel2.Width;
  StartOnBootCheckBox.Height := ScaleY(32);
  StartOnBootCheckBox.Caption := 'Start the receiver with Windows after install';
  StartOnBootCheckBox.Checked := False;
end;
