#define AppName "Manna Send Audio"
#ifndef AppVersion
  #define AppVersion "0.1.0"
#endif
#ifndef SourceDir
  #define SourceDir "..\dist\installer-staging\MannaAudioLink"
#endif
#ifndef OutputDir
  #define OutputDir "..\dist\installer"
#endif
#ifndef DefaultTarget
  #define DefaultTarget ""
#endif

[Setup]
AppId={{1E8E700F-33CC-40D4-9843-F67D4E5E5440}
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
OutputBaseFilename=MannaSendAudio-{#AppVersion}-Sender-Setup
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

[Icons]
Name: "{autoprograms}\{#AppName}"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -NoExit -File ""{app}\launch-manna-send-audio.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\assets\icons\manna-audio-link.ico"
Name: "{autodesktop}\{#AppName}"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -NoExit -File ""{app}\launch-manna-send-audio.ps1"""; WorkingDir: "{app}"; Tasks: desktopicon; IconFilename: "{app}\assets\icons\manna-audio-link.ico"
Name: "{autoprograms}\Configure Manna Send Audio"; Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -NoExit -File ""{app}\configure-sender.ps1"""; WorkingDir: "{app}"; IconFilename: "{app}\assets\icons\manna-audio-link.ico"

[Run]
Filename: "{sys}\WindowsPowerShell\v1.0\powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -NoExit -File ""{app}\launch-manna-send-audio.ps1"""; WorkingDir: "{app}"; Description: "Launch {#AppName}"; Flags: nowait postinstall skipifsilent unchecked

[Code]
var
  SenderPage: TInputQueryWizardPage;

function JsonEscape(Value: String): String;
begin
  Result := Value;
  StringChangeEx(Result, '\', '\\', True);
  StringChangeEx(Result, '"', '\"', True);
end;

procedure InitializeWizard;
begin
  SenderPage := CreateInputQueryPage(
    wpSelectDir,
    'Sender setup',
    'Choose the main PC receiver for this laptop.',
    'Enter the main PC IPv4 address. You can change this later from Configure Manna Send Audio.'
  );
  SenderPage.Add('Main PC receiver IP address:', False);
  SenderPage.Values[0] := ExpandConstant('{param:ReceiverIp|{#DefaultTarget}}');
end;

function NextButtonClick(CurPageID: Integer): Boolean;
begin
  Result := True;
  if Assigned(SenderPage) and (CurPageID = SenderPage.ID) then
  begin
    if Trim(SenderPage.Values[0]) = '' then
    begin
      MsgBox('Enter the main PC receiver IP address, or cancel and install the receiver first.', mbError, MB_OK);
      Result := False;
    end;
  end;
end;

procedure CurStepChanged(CurStep: TSetupStep);
var
  ConfigDir: String;
  ConfigPath: String;
  Target: String;
  Content: String;
begin
  if CurStep = ssPostInstall then
  begin
    Target := Trim(SenderPage.Values[0]);
    ConfigDir := ExpandConstant('{userappdata}\Manna Audio Link');
    ForceDirectories(ConfigDir);
    ConfigPath := ConfigDir + '\sender-config.json';
    Content := '{'#13#10
      + '  "target": "' + JsonEscape(Target) + '",'#13#10
      + '  "port": 44555,'#13#10
      + '  "gain": 0.85,'#13#10
      + '  "block_ms": 10,'#13#10
      + '  "input_device": ""'#13#10
      + '}'#13#10;
    SaveStringToFile(ConfigPath, Content, False);
  end;
end;
