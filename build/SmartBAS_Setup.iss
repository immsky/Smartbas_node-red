; =============================================================================
; SmartBAS BMS — Windows Installer (Inno Setup 6.3+)
; -----------------------------------------------------------------------------
; Compile ONLINE variant (downloads Node.js at install time):
;     iscc SmartBAS_Setup.iss
; Compile OFFLINE variant (bundles Node.js zip, ~55MB output):
;     iscc /DOFFLINE_BUILD SmartBAS_Setup.iss
; =============================================================================

#define AppName            "SmartBAS BMS"
#define AppVersion         "1.0.0"
#define AppPublisher       "SmartBAS Technologies"
#define AppURL             "https://smartbas.local"
#define AppId              "{{B2F7E5A4-9C3D-4F8A-A1E2-7D5B8C9E0F1A}"

#define NodeVersion        "v20.19.0"
#define NodeZipName        "node-v20.19.0-win-x64.zip"
#define NodeZipURL         "https://nodejs.org/dist/v20.19.0/node-v20.19.0-win-x64.zip"
; TODO: replace with the real SHA-256 of node-v20.19.0-win-x64.zip from
; https://nodejs.org/dist/v20.19.0/SHASUMS256.txt before publishing the online build.
#define NodeZipSHA256      "be72284c7bc62de07d5a9fd0ae196879842c085f11f7f2b60bf8864c0c9d6a4f"
#define NodeExtractedDir   "node-v20.19.0-win-x64"

#define DefaultPort        "1880"
#define InstallRoot        "C:\SmartBAS"

[Setup]
AppId={#AppId}
AppName={#AppName}
AppVersion={#AppVersion}
AppVerName={#AppName} {#AppVersion}
AppPublisher={#AppPublisher}
AppPublisherURL={#AppURL}
AppSupportURL={#AppURL}
VersionInfoVersion={#AppVersion}
VersionInfoCompany={#AppPublisher}
VersionInfoDescription=SmartBAS BMS Installer
VersionInfoProductName={#AppName}
DefaultDirName={#InstallRoot}
DefaultGroupName={#AppName}
DisableDirPage=no
DisableProgramGroupPage=yes
DisableWelcomePage=no
AllowNoIcons=yes
PrivilegesRequired=admin
PrivilegesRequiredOverridesAllowed=
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
Compression=lzma2/ultra64
SolidCompression=yes
WizardStyle=modern
SetupIconFile=assets\smartbas.ico
WizardImageFile=assets\banner.bmp
WizardSmallImageFile=assets\smallbanner.bmp
UninstallDisplayIcon={app}\smartbas.ico
UninstallDisplayName={#AppName}
LicenseFile=assets\LICENSE.txt
#ifdef OFFLINE_BUILD
OutputBaseFilename=SmartBAS_Setup_Offline
#else
OutputBaseFilename=SmartBAS_Setup_Online
#endif
OutputDir=output

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Messages]
WelcomeLabel1=Welcome to the [name] Setup Wizard
WelcomeLabel2=Industrial Building Automation Platform powered by SmartBAS Engine v1.0.%n%nThis wizard will install [name/ver] on your computer.%n%nIt is recommended that you close all other applications before continuing.

[Files]
; SmartBAS application — entire forked Node-RED build
Source: "app\*"; DestDir: "{app}\app"; Flags: recursesubdirs createallsubdirs ignoreversion

; NSSM service manager
Source: "tools\nssm.exe"; DestDir: "{app}\tools"; Flags: ignoreversion

; Branding icon
Source: "assets\smartbas.ico"; DestDir: "{app}"; Flags: ignoreversion

; settings.js template — staged to {tmp}, tokens replaced, copied into place by Pascal code
Source: "assets\settings.template.js"; Flags: dontcopy

; Health check script
Source: "tools\healthcheck.ps1"; DestDir: "{app}\tools"; Flags: ignoreversion

; Annual maintenance renewal tool
Source: "tools\renew-license.ps1"; DestDir: "{app}\tools"; Flags: ignoreversion

#ifdef OFFLINE_BUILD
; Bundled Node.js runtime (offline variant only)
Source: "runtime\{#NodeZipName}"; DestDir: "{tmp}"; Flags: deleteafterinstall
#endif

[Dirs]
Name: "{app}\data"; Flags: uninsneveruninstall
Name: "{app}\logs"
Name: "{app}\tools"
Name: "{app}\runtime"

[Icons]
Name: "{group}\SmartBAS BMS"; Filename: "{code:GetDashboardURL}"; IconFilename: "{app}\smartbas.ico"
Name: "{group}\SmartBAS Service Manager"; Filename: "services.msc"; IconFilename: "{sys}\services.msc"
Name: "{group}\SmartBAS Logs"; Filename: "{app}\logs\"
Name: "{group}\Renew SmartBAS License"; Filename: "powershell.exe"; \
  Parameters: "-NoProfile -ExecutionPolicy Bypass -Command ""Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile','-ExecutionPolicy','Bypass','-File','{app}\tools\renew-license.ps1'"""; \
  IconFilename: "{app}\smartbas.ico"; Comment: "Apply an annual maintenance renewal key"
Name: "{group}\Uninstall SmartBAS"; Filename: "{uninstallexe}"
Name: "{commondesktop}\SmartBAS BMS"; Filename: "{code:GetDashboardURL}"; IconFilename: "{app}\smartbas.ico"

[Registry]
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; Flags: uninsdeletekeyifempty
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "InstallPath";  ValueData: "{app}";                 Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "Version";      ValueData: "{#AppVersion}";         Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "Port";         ValueData: "{code:GetPortString}";  Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "LicenseKey";   ValueData: "{code:GetMaskedKey}";   Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "Organization"; ValueData: "{code:GetOrgName}";     Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "Email";        ValueData: "{code:GetEmail}";       Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "InstalledAt";  ValueData: "{code:GetNowISO}";      Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "ExpiresAt";    ValueData: "{code:GetExpiryISOParam}"; Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "LicenseTerm";  ValueData: "365";                   Flags: uninsdeletevalue
Root: HKLM; Subkey: "SOFTWARE\SmartBAS"; ValueType: string; ValueName: "Mode";         ValueData: "{code:GetInstallMode}"; Flags: uninsdeletevalue
; NOTE: SOFTWARE\SmartBAS\Activations is written by Pascal code (NOT listed here)
; so the uninstaller will NOT remove it — license activations are host-locked forever.

[Run]
; ---- Firewall rule ------------------------------------------------------------
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall add rule name=""SmartBAS BMS"" dir=in action=allow protocol=TCP localport={code:GetPortString}"; \
  Flags: runhidden; StatusMsg: "Applying firewall rule..."

; ---- NSSM service registration -----------------------------------------------
Filename: "{app}\tools\nssm.exe"; Parameters: "install SmartBAS ""{app}\runtime\node\node.exe"""; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set SmartBAS AppDirectory ""{app}\app"""; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set SmartBAS AppParameters ""packages\node_modules\node-red\red.js --userDir {app}\data --settings {app}\app\settings.js"""; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set SmartBAS DisplayName ""SmartBAS BMS Service"""; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set SmartBAS Description ""SmartBAS Building Automation Platform"""; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set SmartBAS Start SERVICE_AUTO_START"; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set SmartBAS AppStdout ""{app}\logs\service.log"""; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set SmartBAS AppStderr ""{app}\logs\error.log"""; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set SmartBAS AppRotateFiles 1"; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "set SmartBAS AppRotateBytes 10485760"; \
  Flags: runhidden; StatusMsg: "Registering SmartBAS Windows service..."
Filename: "{app}\tools\nssm.exe"; Parameters: "start SmartBAS"; \
  Flags: runhidden; StatusMsg: "Starting SmartBAS service..."

; ---- Finish page: optional dashboard launch & health check -------------------
Filename: "{code:GetDashboardURL}"; Description: "Launch SmartBAS Dashboard in browser"; \
  Flags: postinstall shellexec nowait skipifsilent
Filename: "powershell.exe"; Parameters: "-NoProfile -ExecutionPolicy Bypass -File ""{app}\tools\healthcheck.ps1"" -Port {code:GetPortString} -InstallRoot ""{app}"""; \
  Description: "Run post-install health check"; Flags: postinstall runhidden skipifsilent

[UninstallRun]
Filename: "{app}\tools\nssm.exe"; Parameters: "stop SmartBAS";           Flags: runhidden; RunOnceId: "StopSmartBAS"
Filename: "{app}\tools\nssm.exe"; Parameters: "remove SmartBAS confirm"; Flags: runhidden; RunOnceId: "RemoveSmartBAS"
Filename: "{sys}\netsh.exe"; Parameters: "advfirewall firewall delete rule name=""SmartBAS BMS"""; Flags: runhidden; RunOnceId: "RemoveFirewall"

[UninstallDelete]
Type: filesandordirs; Name: "{app}\app"
Type: filesandordirs; Name: "{app}\runtime"
Type: filesandordirs; Name: "{app}\tools"
Type: filesandordirs; Name: "{app}\logs"
Type: files;          Name: "{app}\smartbas.ico"
Type: files;          Name: "{app}\license.json"
; NOTE: {app}\data is deliberately NOT deleted (user flows/credentials are preserved)

; =============================================================================
; [Code] — Pascal scripting
; =============================================================================
[Code]
const
  REG_SMARTBAS      = 'SOFTWARE\SmartBAS';
  REG_ACTIVATIONS   = 'SOFTWARE\SmartBAS\Activations';
  REG_HOST_BINDING  = 'SOFTWARE\SmartBAS\HostBinding';
  REG_MACHINE_GUID  = 'SOFTWARE\Microsoft\Cryptography';

var
  // License page controls
  LicensePage: TWizardPage;
  EditLicenseKey: TNewEdit;
  EditOrgName: TNewEdit;
  EditEmail: TNewEdit;
  BtnValidate: TNewButton;
  LblStatus: TNewStaticText;
  LicenseValidated: Boolean;
  FormattingInProgress: Boolean;

  // Port page
  PortPage: TInputQueryWizardPage;

  // Download progress page (online mode only)
  DownloadPage: TDownloadWizardPage;

  // Installation state
  SelectedPort: String;
  OfflineMode: Boolean;
  UpgradeMode: Boolean;
  MachineGuidCache: String;

// -----------------------------------------------------------------------------
// License key pool — embedded in compiled binary. Add more keys here and
// recompile to issue additional licenses.
// -----------------------------------------------------------------------------
function ValidKeys(): TArrayOfString;
var
  K: TArrayOfString;
begin
  SetArrayLength(K, 50);
  K[0]  := 'SMBAS-A3K9-MX72-BQ4T-ZR81';
  K[1]  := 'SMBAS-F7NP-CW56-HJ2D-YL30';
  K[2]  := 'SMBAS-T1RV-EK84-QA6U-PD95';
  K[3]  := 'SMBAS-G8WS-LB47-NF3X-CM20';
  K[4]  := 'SMBAS-Z5JH-OU91-KT6E-WR43';
  K[5]  := 'SMBAS-B2DM-YV38-SF7P-XN64';
  K[6]  := 'SMBAS-H9QA-IC50-RW1L-TG72';
  K[7]  := 'SMBAS-P4KN-MZ63-DJ8B-UE91';
  K[8]  := 'SMBAS-W6TF-XR27-AH5C-QL48';
  K[9]  := 'SMBAS-E3VB-SK90-GM4Y-NP15';
  K[10] := 'SMBAS-L7CW-PD81-TF2X-HJ56';
  K[11] := 'SMBAS-N1GZ-UA44-BK9R-EQ73';
  K[12] := 'SMBAS-R5XM-WL69-CP3S-FT28';
  K[13] := 'SMBAS-U8AK-HN32-ZV7D-MB40';
  K[14] := 'SMBAS-C6PY-QT85-LW1F-JG97';
  K[15] := 'SMBAS-D4HB-EX70-NK6A-SR23';
  K[16] := 'SMBAS-K2VQ-FJ58-TM9P-WC61';
  K[17] := 'SMBAS-M9NL-GR43-UC5Z-XT87';
  K[18] := 'SMBAS-Q7DT-AW26-HE8B-YK14';
  K[19] := 'SMBAS-S0FK-BM91-PX3V-ZL59';
  K[20] := 'SMBAS-V3YC-KQ74-RN6G-DH82';
  K[21] := 'SMBAS-X1PW-TZ50-MF4J-CA36';
  K[22] := 'SMBAS-Y6LS-UB83-QD7K-NR29';
  K[23] := 'SMBAS-J8MH-CV45-WG2T-PX60';
  K[24] := 'SMBAS-I5RN-DZ97-EL1B-KF38';
  K[25] := 'SMBAS-A7KW-MX34-BQ8T-ZR52';
  K[26] := 'SMBAS-F2NP-CW91-HJ6D-YL75';
  K[27] := 'SMBAS-T4RV-EK28-QA0U-PD63';
  K[28] := 'SMBAS-G1WS-LB70-NF9X-CM84';
  K[29] := 'SMBAS-Z8JH-OU45-KT2E-WR17';
  K[30] := 'SMBAS-B6DM-YV83-SF1P-XN40';
  K[31] := 'SMBAS-H3QA-IC76-RW5L-TG29';
  K[32] := 'SMBAS-P9KN-MZ18-DJ4B-UE53';
  K[33] := 'SMBAS-W0TF-XR61-AH9C-QL22';
  K[34] := 'SMBAS-E7VB-SK34-GM8Y-NP89';
  K[35] := 'SMBAS-L4CW-PD57-TF6X-HJ10';
  K[36] := 'SMBAS-N5GZ-UA92-BK3R-EQ46';
  K[37] := 'SMBAS-R2XM-WL25-CP7S-FT81';
  K[38] := 'SMBAS-U1AK-HN68-ZV4D-MB93';
  K[39] := 'SMBAS-C9PY-QT01-LW5F-JG37';
  K[40] := 'SMBAS-D8HB-EX46-NK2A-SR70';
  K[41] := 'SMBAS-K6VQ-FJ89-TM3P-WC14';
  K[42] := 'SMBAS-M3NL-GR57-UC9Z-XT42';
  K[43] := 'SMBAS-Q0DT-AW72-HE4B-YK68';
  K[44] := 'SMBAS-S5FK-BM39-PX7V-ZL23';
  K[45] := 'SMBAS-V8YC-KQ16-RN2G-DH55';
  K[46] := 'SMBAS-X4PW-TZ83-MF8J-CA90';
  K[47] := 'SMBAS-Y1LS-UB47-QD3K-NR72';
  K[48] := 'SMBAS-J6MH-CV20-WG8T-PX15';
  K[49] := 'SMBAS-I9RN-DZ53-EL5B-KF84';
  Result := K;
end;

// -----------------------------------------------------------------------------
// String helpers
// -----------------------------------------------------------------------------
function IsUpperAlphaNum(C: Char): Boolean;
begin
  Result := ((C >= 'A') and (C <= 'Z')) or ((C >= '0') and (C <= '9'));
end;

// Validate format: SMBAS-XXXX-XXXX-XXXX-XXXX (exactly, uppercase A-Z/0-9)
function IsKeyFormatValid(Key: String): Boolean;
var
  i: Integer;
begin
  Result := False;
  if Length(Key) <> 25 then Exit;
  if Copy(Key, 1, 6) <> 'SMBAS-' then Exit;
  // positions 1..5 = 'SMBAS', 6 = '-'
  // segments at: 7..10, 12..15, 17..20, 22..25  with dashes at 11,16,21
  for i := 7 to 10 do if not IsUpperAlphaNum(Key[i]) then Exit;
  if Key[11] <> '-' then Exit;
  for i := 12 to 15 do if not IsUpperAlphaNum(Key[i]) then Exit;
  if Key[16] <> '-' then Exit;
  for i := 17 to 20 do if not IsUpperAlphaNum(Key[i]) then Exit;
  if Key[21] <> '-' then Exit;
  for i := 22 to 25 do if not IsUpperAlphaNum(Key[i]) then Exit;
  Result := True;
end;

// -----------------------------------------------------------------------------
// Key pool / activation registry
// -----------------------------------------------------------------------------
function IsKeyInPool(Key: String): Boolean;
var
  Pool: TArrayOfString;
  i: Integer;
begin
  Result := False;
  Pool := ValidKeys();
  for i := 0 to GetArrayLength(Pool) - 1 do begin
    if Pool[i] = Key then begin
      Result := True;
      Exit;
    end;
  end;
end;

function IsKeyAlreadyActivated(Key: String): Boolean;
var
  Existing: String;
begin
  Result := RegQueryStringValue(HKEY_LOCAL_MACHINE, REG_ACTIVATIONS, Key, Existing)
            and (Existing <> '');
end;

function GetMachineGuid(): String;
begin
  if MachineGuidCache <> '' then begin
    Result := MachineGuidCache;
    Exit;
  end;
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE, REG_MACHINE_GUID, 'MachineGuid', Result) then
    Result := 'UNKNOWN';
  MachineGuidCache := Result;
end;

function GetISOTimestamp(): String;
begin
  // yyyy-mm-ddThh:nn:ssZ (local time, Z suffix for convenience)
  Result := GetDateTimeString('yyyy/mm/dd''T''hh:nn:ss', '-', ':') + 'Z';
end;

// Today's date in human form: "April 5, 2026"
function GetTodayHuman(): String;
var
  Today, Day: String;
  MonthIdx: Integer;
  Months: array[1..12] of String;
begin
  Months[1]  := 'January';   Months[2]  := 'February'; Months[3]  := 'March';
  Months[4]  := 'April';     Months[5]  := 'May';      Months[6]  := 'June';
  Months[7]  := 'July';      Months[8]  := 'August';   Months[9]  := 'September';
  Months[10] := 'October';   Months[11] := 'November'; Months[12] := 'December';
  Today := GetDateTimeString('yyyy/mm/dd', '-', ':');  // 'yyyy-mm-dd'
  MonthIdx := StrToIntDef(Copy(Today, 6, 2), 1);
  if (MonthIdx < 1) or (MonthIdx > 12) then MonthIdx := 1;
  Day := Copy(Today, 9, 2);
  if Copy(Day, 1, 1) = '0' then Day := Copy(Day, 2, 1);
  Result := Months[MonthIdx] + ' ' + Day + ', ' + Copy(Today, 1, 4);
end;

// Today + 365 days in both ISO (for JSON) and human form (for UI)
// Add one year to an ISO-style date string "yyyy-mm-ddThh:nn:ssZ" by bumping year.
// Simple, deterministic, and avoids TDateTime arithmetic (not exposed in Inno Pascal).
function AddOneYearToISO(ISO: String): String;
var
  YearStr: String;
  YearNum: Integer;
begin
  // ISO = 'yyyy-mm-ddThh:nn:ssZ' (20 chars). Year at positions 1..4.
  YearStr := Copy(ISO, 1, 4);
  YearNum := StrToIntDef(YearStr, 2026) + 1;
  Result := IntToStr(YearNum) + Copy(ISO, 5, Length(ISO) - 4);
end;

function GetExpiryISO(): String;
begin
  Result := AddOneYearToISO(GetISOTimestamp());
end;

function GetExpiryHuman(): String;
var
  Today, Parts: String;
  Year, MonthIdx: Integer;
  Day: String;
  Months: array[1..12] of String;
begin
  Months[1]  := 'January';   Months[2]  := 'February'; Months[3]  := 'March';
  Months[4]  := 'April';     Months[5]  := 'May';      Months[6]  := 'June';
  Months[7]  := 'July';      Months[8]  := 'August';   Months[9]  := 'September';
  Months[10] := 'October';   Months[11] := 'November'; Months[12] := 'December';
  Today := GetDateTimeString('yyyy/mm/dd', '-', ':');  // 'yyyy-mm-dd'
  Year := StrToIntDef(Copy(Today, 1, 4), 2026) + 1;
  MonthIdx := StrToIntDef(Copy(Today, 6, 2), 1);
  if (MonthIdx < 1) or (MonthIdx > 12) then MonthIdx := 1;
  Day := Copy(Today, 9, 2);
  // Trim leading zero on day
  if Copy(Day, 1, 1) = '0' then Day := Copy(Day, 2, 1);
  Result := Months[MonthIdx] + ' ' + Day + ', ' + IntToStr(Year);
end;

procedure MarkKeyAsActivated(Key: String; MachineGuid: String);
var
  Payload: String;
begin
  Payload := MachineGuid + '|' + GetISOTimestamp();
  if not RegWriteStringValue(HKEY_LOCAL_MACHINE, REG_ACTIVATIONS, Key, Payload) then
    Log('WARNING: Failed to write activation record for key.');
end;

// -----------------------------------------------------------------------------
// Host binding — permanent per-machine license lock.
// Once a key is bound here, THIS computer can only be (re)activated with the
// same key. Different keys entered on this machine will be rejected.
// These registry values are NEVER deleted by the uninstaller, matching the
// Niagara N4 host-locked licensing model.
// -----------------------------------------------------------------------------
function GetBoundKey(): String;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE, REG_HOST_BINDING, 'LicenseKey', Result) then
    Result := '';
end;

function GetBoundHostId(): String;
begin
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE, REG_HOST_BINDING, 'HostId', Result) then
    Result := '';
end;

procedure BindKeyToMachine(Key: String);
var
  HostId: String;
begin
  HostId := GetMachineGuid();
  RegWriteStringValue(HKEY_LOCAL_MACHINE, REG_HOST_BINDING, 'LicenseKey', Key);
  RegWriteStringValue(HKEY_LOCAL_MACHINE, REG_HOST_BINDING, 'HostId', HostId);
  RegWriteStringValue(HKEY_LOCAL_MACHINE, REG_HOST_BINDING, 'BoundAt', GetISOTimestamp());
end;

// -----------------------------------------------------------------------------
// Mask the last license key for display / registry (shows only final 4 chars)
// -----------------------------------------------------------------------------
function MaskKey(Key: String): String;
begin
  if Length(Key) = 25 then
    Result := 'SMBAS-****-****-****-' + Copy(Key, 22, 4)
  else
    Result := 'SMBAS-****-****-****-****';
end;

// -----------------------------------------------------------------------------
// Installer expressions (called from [Registry], [Run], [Icons] via {code:...})
// -----------------------------------------------------------------------------
function GetPortString(Param: String): String;
begin
  Result := SelectedPort;
  if Result = '' then Result := '{#DefaultPort}';
end;

function GetMaskedKey(Param: String): String;
begin
  Result := MaskKey(Trim(EditLicenseKey.Text));
end;

function GetOrgName(Param: String): String;
begin
  Result := Trim(EditOrgName.Text);
end;

function GetEmail(Param: String): String;
begin
  Result := Trim(EditEmail.Text);
end;

function GetNowISO(Param: String): String;
begin
  Result := GetISOTimestamp();
end;

function GetExpiryISOParam(Param: String): String;
begin
  Result := GetExpiryISO();
end;

function GetInstallMode(Param: String): String;
begin
  if OfflineMode then Result := 'offline' else Result := 'online';
end;

function GetDashboardURL(Param: String): String;
begin
  Result := 'http://localhost:' + GetPortString('');
end;

// -----------------------------------------------------------------------------
// Port conflict detection (netstat scrape)
// -----------------------------------------------------------------------------
function IsPortInUse(Port: String): Boolean;
var
  TmpFile, Cmd: String;
  Contents: AnsiString;
  ResultCode: Integer;
begin
  Result := False;
  TmpFile := ExpandConstant('{tmp}\portscan.txt');
  Cmd := '/C netstat -ano -p TCP | findstr LISTENING | findstr ":' + Port + ' " > "' + TmpFile + '"';
  Exec(ExpandConstant('{cmd}'), Cmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  if LoadStringFromFile(TmpFile, Contents) then
    Result := Length(Contents) > 0;
  DeleteFile(TmpFile);
end;

function FindNextFreePort(StartPort: Integer): Integer;
var
  P: Integer;
begin
  P := StartPort;
  while (P < StartPort + 100) and IsPortInUse(IntToStr(P)) do
    P := P + 1;
  Result := P;
end;

// -----------------------------------------------------------------------------
// License key auto-formatting (inserts dashes as user types)
// -----------------------------------------------------------------------------
procedure LicenseKeyOnChange(Sender: TObject);
var
  Raw, Clean, Formatted: String;
  i: Integer;
  C: Char;
begin
  if FormattingInProgress then Exit;
  FormattingInProgress := True;
  try
    Raw := Uppercase(EditLicenseKey.Text);
    // Strip every char except A-Z and 0-9
    Clean := '';
    for i := 1 to Length(Raw) do begin
      C := Raw[i];
      if IsUpperAlphaNum(C) then Clean := Clean + C;
    end;
    // Clean now holds raw alphanumerics. Key is SMBAS + 16 alphanum = 21 chars max.
    if Length(Clean) > 21 then Clean := Copy(Clean, 1, 21);
    // Re-insert dashes at the 5/9/13/17 boundaries
    Formatted := '';
    for i := 1 to Length(Clean) do begin
      if (i = 6) or (i = 10) or (i = 14) or (i = 18) then
        Formatted := Formatted + '-';
      Formatted := Formatted + Clean[i];
    end;
    if Formatted <> EditLicenseKey.Text then begin
      EditLicenseKey.Text := Formatted;
      EditLicenseKey.SelStart := Length(Formatted);
    end;
    // Any edit invalidates a prior validation
    LicenseValidated := False;
    LblStatus.Caption := '';
    WizardForm.NextButton.Enabled := False;
  finally
    FormattingInProgress := False;
  end;
end;

// -----------------------------------------------------------------------------
// [Validate License] click handler
// -----------------------------------------------------------------------------
procedure ValidateButtonClick(Sender: TObject);
var
  Key, BoundKey, ExistingRecord, RecordedHostId, BarPos: String;
  BarPosInt: Integer;
begin
  LicenseValidated := False;
  WizardForm.NextButton.Enabled := False;
  Key := Uppercase(Trim(EditLicenseKey.Text));

  // ---- Step 1: format ----
  if not IsKeyFormatValid(Key) then begin
    LblStatus.Font.Color := $000000C0;
    LblStatus.Caption := 'X  Invalid license key - check format and try again';
    Exit;
  end;

  // ---- Step 2: in pool? ----
  if not IsKeyInPool(Key) then begin
    LblStatus.Font.Color := $000000C0;
    LblStatus.Caption := 'X  Invalid license key - check format and try again';
    Exit;
  end;

  // ---- Step 3: host binding enforcement ----
  // If THIS computer is already bound to some license key, only that same key
  // may be used here. Block any other key — even from the valid pool.
  BoundKey := GetBoundKey();
  if (BoundKey <> '') and (BoundKey <> Key) then begin
    LblStatus.Font.Color := $000000C0;
    LblStatus.Caption := 'X  This computer is already bound to a different SmartBAS license.' + #13#10 +
                         '    Please enter the original key that was used on this machine' + #13#10 +
                         '    (ending in ...' + Copy(BoundKey, 22, 4) + '), or contact SmartBAS support.';
    Exit;
  end;

  // ---- Step 4: cross-machine reuse check ----
  // If this key has an activation record, its stored MachineGuid must match
  // the current machine. If a different MachineGuid is recorded, the key is
  // bound elsewhere and cannot be used here.
  if RegQueryStringValue(HKEY_LOCAL_MACHINE, REG_ACTIVATIONS, Key, ExistingRecord) and (ExistingRecord <> '') then begin
    BarPosInt := Pos('|', ExistingRecord);
    if BarPosInt > 0 then
      RecordedHostId := Copy(ExistingRecord, 1, BarPosInt - 1)
    else
      RecordedHostId := ExistingRecord;
    if RecordedHostId <> GetMachineGuid() then begin
      LblStatus.Font.Color := $000000C0;
      LblStatus.Caption := 'X  This license key is already bound to a different computer.' + #13#10 +
                           '    Each key can only be activated on one machine. Contact' + #13#10 +
                           '    SmartBAS support for a replacement key.';
      Exit;
    end;
  end;

  // ---- All checks passed ----
  LblStatus.Font.Color := $00008000;  // green (BGR)
  if BoundKey = Key then
    LblStatus.Caption := 'OK  License valid - re-activation on bound machine'
  else
    LblStatus.Caption := 'OK  License valid - SmartBAS BMS ready to activate';
  LicenseValidated := True;
  WizardForm.NextButton.Enabled := True;
end;

// -----------------------------------------------------------------------------
// Build the custom License Activation wizard page
// -----------------------------------------------------------------------------
procedure CreateLicensePage();
var
  Y: Integer;
  Lbl: TNewStaticText;
begin
  LicensePage := CreateCustomPage(wpLicense,
    'SmartBAS License Activation',
    'Enter your license key to activate SmartBAS BMS.');

  Y := 8;

  // --- License Key ---
  Lbl := TNewStaticText.Create(LicensePage);
  Lbl.Parent := LicensePage.Surface;
  Lbl.Caption := 'License Key:';
  Lbl.Top := Y; Lbl.Left := 0;
  Y := Y + 18;

  EditLicenseKey := TNewEdit.Create(LicensePage);
  EditLicenseKey.Parent := LicensePage.Surface;
  EditLicenseKey.Top := Y; EditLicenseKey.Left := 0;
  EditLicenseKey.Width := LicensePage.SurfaceWidth - 8;
  EditLicenseKey.CharCase := ecUpperCase;
  EditLicenseKey.MaxLength := 25;
  EditLicenseKey.OnChange := @LicenseKeyOnChange;
  Y := Y + 28;

  // --- Organization / Site ---
  Lbl := TNewStaticText.Create(LicensePage);
  Lbl.Parent := LicensePage.Surface;
  Lbl.Caption := 'Organization / Site Name:';
  Lbl.Top := Y; Lbl.Left := 0;
  Y := Y + 18;

  EditOrgName := TNewEdit.Create(LicensePage);
  EditOrgName.Parent := LicensePage.Surface;
  EditOrgName.Top := Y; EditOrgName.Left := 0;
  EditOrgName.Width := LicensePage.SurfaceWidth - 8;
  EditOrgName.MaxLength := 128;
  Y := Y + 28;

  // --- Registered Email ---
  Lbl := TNewStaticText.Create(LicensePage);
  Lbl.Parent := LicensePage.Surface;
  Lbl.Caption := 'Registered Email:';
  Lbl.Top := Y; Lbl.Left := 0;
  Y := Y + 18;

  EditEmail := TNewEdit.Create(LicensePage);
  EditEmail.Parent := LicensePage.Surface;
  EditEmail.Top := Y; EditEmail.Left := 0;
  EditEmail.Width := LicensePage.SurfaceWidth - 8;
  EditEmail.MaxLength := 128;
  Y := Y + 34;

  // --- Validate button ---
  BtnValidate := TNewButton.Create(LicensePage);
  BtnValidate.Parent := LicensePage.Surface;
  BtnValidate.Top := Y; BtnValidate.Left := 0;
  BtnValidate.Width := 140; BtnValidate.Height := 24;
  BtnValidate.Caption := 'Validate License';
  BtnValidate.OnClick := @ValidateButtonClick;
  Y := Y + 32;

  // --- Status label ---
  LblStatus := TNewStaticText.Create(LicensePage);
  LblStatus.Parent := LicensePage.Surface;
  LblStatus.Top := Y; LblStatus.Left := 0;
  LblStatus.Width := LicensePage.SurfaceWidth - 8;
  LblStatus.AutoSize := False;
  LblStatus.Height := 40;
  LblStatus.Caption := '';
  LblStatus.Font.Style := [fsBold];

  // --- License term notice (always visible) ---
  Y := Y + 48;
  Lbl := TNewStaticText.Create(LicensePage);
  Lbl.Parent := LicensePage.Surface;
  Lbl.AutoSize := False;
  Lbl.Top := Y; Lbl.Left := 0;
  Lbl.Width := LicensePage.SurfaceWidth - 8;
  Lbl.Height := 56;
  Lbl.WordWrap := True;
  Lbl.Font.Color := $00606060;
  Lbl.Caption :=
    'This license is valid for 365 days from the installation date.' + #13#10 +
    'Activation date: ' + GetTodayHuman() + #13#10 +
    'Expires on:      ' + GetExpiryHuman() + #13#10 +
    'Annual maintenance renewal required after expiry for continued support.';
end;

// -----------------------------------------------------------------------------
// Port selection page
// -----------------------------------------------------------------------------
procedure CreatePortPage();
begin
  PortPage := CreateInputQueryPage(LicensePage.ID,
    'Service Port',
    'Choose the TCP port for the SmartBAS dashboard.',
    'SmartBAS will listen on this port (default 1880). If the port is already in use on this machine, the next free port will be suggested.');
  PortPage.Add('Port:', False);
  PortPage.Values[0] := '{#DefaultPort}';
end;

// -----------------------------------------------------------------------------
// Detect existing install (upgrade path)
// -----------------------------------------------------------------------------
function DetectExistingInstall(): Boolean;
var
  Dummy: String;
begin
  Result := RegQueryStringValue(HKEY_LOCAL_MACHINE, REG_SMARTBAS, 'InstallPath', Dummy);
end;

function BackupExistingData(InstallPath: String): Boolean;
var
  DataDir, BackupDir, Stamp: String;
  ResultCode: Integer;
begin
  Result := True;
  DataDir := InstallPath + '\data';
  if not DirExists(DataDir) then Exit;
  Stamp := GetDateTimeString('yyyymmdd_hhnnss', '', '');
  BackupDir := InstallPath + '\data_backup_' + Stamp;
  Exec(ExpandConstant('{cmd}'),
       '/C xcopy "' + DataDir + '" "' + BackupDir + '" /E /I /H /Y > nul',
       '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
  Result := (ResultCode = 0);
end;

// -----------------------------------------------------------------------------
// Online connectivity check (HEAD request to nodejs.org)
// -----------------------------------------------------------------------------
function HasInternet(): Boolean;
var
  WinHttpReq: Variant;
begin
  Result := False;
  try
    WinHttpReq := CreateOleObject('WinHttp.WinHttpRequest.5.1');
    WinHttpReq.SetTimeouts(5000, 5000, 5000, 5000);
    WinHttpReq.Open('HEAD', 'https://nodejs.org/dist/', False);
    WinHttpReq.Send('');
    Result := (WinHttpReq.Status = 200) or (WinHttpReq.Status = 301) or (WinHttpReq.Status = 302);
  except
    Result := False;
  end;
end;

// -----------------------------------------------------------------------------
// Extract Node.js zip via PowerShell (Expand-Archive ships with Win10+)
// -----------------------------------------------------------------------------
function ExtractNodeZip(ZipPath, DestDir: String): Boolean;
var
  Cmd: String;
  ResultCode: Integer;
begin
  ForceDirectories(DestDir);
  Cmd := '-NoProfile -ExecutionPolicy Bypass -Command ' +
         '"Expand-Archive -LiteralPath ''' + ZipPath + ''' -DestinationPath ''' + DestDir + ''' -Force"';
  Result := Exec('powershell.exe', Cmd, '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
            and (ResultCode = 0);
end;

function RelocateNodeRuntime(ExtractedRoot: String): Boolean;
var
  InnerDir, NodeDir: String;
  ResultCode: Integer;
begin
  // Zip contains node-v20.19.0-win-x64\* — move its contents into runtime\node\
  InnerDir := ExtractedRoot + '\{#NodeExtractedDir}';
  NodeDir := ExtractedRoot + '\node';
  if not DirExists(InnerDir) then begin
    Result := False;
    Exit;
  end;
  Result := Exec(ExpandConstant('{cmd}'),
                 '/C move "' + InnerDir + '" "' + NodeDir + '" > nul',
                 '', SW_HIDE, ewWaitUntilTerminated, ResultCode)
            and (ResultCode = 0);
end;

// -----------------------------------------------------------------------------
// Write license.json
// -----------------------------------------------------------------------------
procedure WriteLicenseJson();
var
  Path, Json, Key, Masked: String;
  Lines: TArrayOfString;
begin
  Key := Uppercase(Trim(EditLicenseKey.Text));
  Masked := MaskKey(Key);
  Path := ExpandConstant('{app}\license.json');
  Json :=
    '{' + #13#10 +
    '  "licenseKey": "' + Key + '",' + #13#10 +
    '  "maskedKey": "' + Masked + '",' + #13#10 +
    '  "organization": "' + Trim(EditOrgName.Text) + '",' + #13#10 +
    '  "email": "' + Trim(EditEmail.Text) + '",' + #13#10 +
    '  "activatedAt": "' + GetISOTimestamp() + '",' + #13#10 +
    '  "expiresAt": "' + GetExpiryISO() + '",' + #13#10 +
    '  "maintenanceUntil": "' + GetExpiryISO() + '",' + #13#10 +
    '  "licenseTermDays": 365,' + #13#10 +
    '  "hostId": "' + GetMachineGuid() + '",' + #13#10 +
    '  "version": "{#AppVersion}",' + #13#10 +
    '  "product": "SmartBAS BMS"' + #13#10 +
    '}' + #13#10;
  SetArrayLength(Lines, 1);
  Lines[0] := Json;
  SaveStringToFile(Path, Json, False);
end;

// -----------------------------------------------------------------------------
// Emit pre-configured settings.js (from template, with tokens replaced)
// -----------------------------------------------------------------------------
function GenerateCredentialSecret(): String;
var
  GuidPart: String;
  i: Integer;
begin
  GuidPart := GetMachineGuid() + GetISOTimestamp();
  Result := '';
  for i := 1 to Length(GuidPart) do
    if IsUpperAlphaNum(Uppercase(GuidPart[i])[1]) then
      Result := Result + GuidPart[i];
  if Length(Result) > 48 then Result := Copy(Result, 1, 48);
end;

// Escape backslashes for embedding in a JavaScript string literal.
// C:\SmartBAS -> C:\\SmartBAS
function EscapeBackslashes(S: String): String;
begin
  Result := S;
  StringChangeEx(Result, '\', '\\', True);
end;

procedure WriteSettingsJs();
var
  TemplatePath, OutPath, InstallPathJS: String;
  Content: AnsiString;
  Text: String;
begin
  TemplatePath := ExpandConstant('{tmp}\settings.template.js');
  OutPath := ExpandConstant('{app}\app\settings.js');
  ExtractTemporaryFile('settings.template.js');
  if not LoadStringFromFile(TemplatePath, Content) then begin
    Log('ERROR: could not read settings.template.js');
    Exit;
  end;
  Text := String(Content);
  // Escape backslashes once — template already uses \\ for path separators,
  // so INSTALL_PATH_PLACEHOLDER in the template appears as "C:\\SmartBAS\\app\\..."
  // after substitution, which evaluates correctly in JavaScript.
  InstallPathJS := EscapeBackslashes(ExpandConstant('{app}'));
  StringChangeEx(Text, 'PORT_PLACEHOLDER', SelectedPort, True);
  StringChangeEx(Text, 'CREDENTIAL_SECRET_PLACEHOLDER', GenerateCredentialSecret(), True);
  StringChangeEx(Text, 'INSTALL_PATH_PLACEHOLDER', InstallPathJS, True);
  ForceDirectories(ExpandConstant('{app}\app'));
  SaveStringToFile(OutPath, Text, False);
end;

// -----------------------------------------------------------------------------
// Wizard event hooks
// -----------------------------------------------------------------------------
procedure InitializeWizard();
var
  Param: Integer;
begin
  LicenseValidated := False;
  OfflineMode := False;
  UpgradeMode := False;
  SelectedPort := '{#DefaultPort}';

  // Honor /OFFLINE CLI flag
  for Param := 1 to ParamCount() do
    if CompareText(ParamStr(Param), '/OFFLINE') = 0 then OfflineMode := True;
#ifdef OFFLINE_BUILD
  OfflineMode := True;
#endif

  // Detect upgrade
  UpgradeMode := DetectExistingInstall();

  // Custom pages
  CreateLicensePage();
  CreatePortPage();

  // Download page (always created; only used in online mode)
  DownloadPage := CreateDownloadPage(
    'Downloading Node.js Runtime',
    'SmartBAS is fetching the Node.js 20 LTS runtime from nodejs.org.',
    nil);
end;

// Cache selected port as user leaves the port page
function NextButtonClick(CurPageID: Integer): Boolean;
var
  PortNum: Integer;
  NextFree: Integer;
begin
  Result := True;
  if CurPageID = LicensePage.ID then begin
    if not LicenseValidated then begin
      MsgBox('Please validate your license key before continuing.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
    if Trim(EditOrgName.Text) = '' then begin
      MsgBox('Please enter your organization / site name.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
    if Trim(EditEmail.Text) = '' then begin
      MsgBox('Please enter a registered email address.', mbError, MB_OK);
      Result := False;
      Exit;
    end;
  end
  else if CurPageID = PortPage.ID then begin
    SelectedPort := Trim(PortPage.Values[0]);
    if (SelectedPort = '') or (StrToIntDef(SelectedPort, -1) <= 0) or (StrToIntDef(SelectedPort, -1) > 65535) then begin
      MsgBox('Please enter a valid TCP port (1-65535).', mbError, MB_OK);
      Result := False;
      Exit;
    end;
    PortNum := StrToInt(SelectedPort);
    if IsPortInUse(SelectedPort) then begin
      NextFree := FindNextFreePort(PortNum);
      if MsgBox('Port ' + SelectedPort + ' is already in use.' + #13#10 +
                'Use next free port ' + IntToStr(NextFree) + ' instead?',
                mbConfirmation, MB_YESNO) = IDYES then begin
        SelectedPort := IntToStr(NextFree);
        PortPage.Values[0] := SelectedPort;
      end else begin
        Result := False;
        Exit;
      end;
    end;
  end
  else if CurPageID = wpReady then begin
    // Online download happens here, before file copy begins
    if not OfflineMode then begin
      if not HasInternet() then begin
        MsgBox('No internet connection detected. Falling back to offline mode — ' +
               'please use SmartBAS_Setup_Offline.exe instead, or re-run with /OFFLINE.',
               mbInformation, MB_OK);
        OfflineMode := True;
        Result := False;
        Exit;
      end;
      DownloadPage.Clear;
      DownloadPage.Add('{#NodeZipURL}', '{#NodeZipName}', '{#NodeZipSHA256}');
      DownloadPage.Show;
      try
        try
          DownloadPage.Download;
        except
          MsgBox('Failed to download Node.js runtime:' + #13#10 + GetExceptionMessage, mbError, MB_OK);
          Result := False;
          Exit;
        end;
      finally
        DownloadPage.Hide;
      end;
    end;
  end;
end;

// Build the "Ready to Install" page summary text
function UpdateReadyMemo(Space, NewLine, MemoUserInfoInfo, MemoDirInfo, MemoTypeInfo,
  MemoComponentsInfo, MemoGroupInfo, MemoTasksInfo: String): String;
var
  S, ModeStr: String;
begin
  if OfflineMode then
    ModeStr := 'Offline (bundled Node.js runtime)'
  else
    ModeStr := 'Online (download Node.js from nodejs.org)';
  S := '';
  S := S + 'Organization:' + NewLine + Space + Trim(EditOrgName.Text) + NewLine + NewLine;
  S := S + 'License key:'  + NewLine + Space + MaskKey(Uppercase(Trim(EditLicenseKey.Text))) + NewLine + NewLine;
  S := S + 'Email:'        + NewLine + Space + Trim(EditEmail.Text) + NewLine + NewLine;
  S := S + 'Install path:' + NewLine + Space + ExpandConstant('{app}') + NewLine + NewLine;
  S := S + 'Service port:' + NewLine + Space + SelectedPort + NewLine + NewLine;
  S := S + 'Mode:'         + NewLine + Space + ModeStr + NewLine + NewLine;
  S := S + 'License term:' + NewLine + Space + '365 days  (' + GetTodayHuman() + '  to  ' + GetExpiryHuman() + ')' + NewLine;
  if UpgradeMode then
    S := S + NewLine + 'Existing installation detected — upgrade mode (data will be backed up).' + NewLine;
  Result := S;
end;

procedure CurPageChanged(CurPageID: Integer);
begin
  if CurPageID = LicensePage.ID then begin
    WizardForm.NextButton.Enabled := LicenseValidated;
    WizardForm.ActiveControl := EditLicenseKey;
  end;
end;

// Hide license entry page on upgrade (machine is already activated)
function ShouldSkipPage(PageID: Integer): Boolean;
begin
  Result := False;
  if UpgradeMode and (PageID = LicensePage.ID) then Result := True;
end;

// -----------------------------------------------------------------------------
// Install step hook — orchestrate Node.js extraction, settings, license.json
// -----------------------------------------------------------------------------
procedure CurStepChanged(CurStep: TSetupStep);
var
  ZipSrc, ZipStaged, RuntimeDir, Key, MachineGuid: String;
  ResultCode: Integer;
begin
  if CurStep = ssInstall then begin
    if UpgradeMode then begin
      WizardForm.StatusLabel.Caption := 'Backing up existing data...';
      BackupExistingData(ExpandConstant('{app}'));
      Exec(ExpandConstant('{app}\tools\nssm.exe'), 'stop SmartBAS', '', SW_HIDE,
           ewWaitUntilTerminated, ResultCode);
    end;
  end
  else if CurStep = ssPostInstall then begin
    RuntimeDir := ExpandConstant('{app}\runtime');
    ForceDirectories(RuntimeDir);

    // 1. Stage the Node.js zip
    WizardForm.StatusLabel.Caption := 'Extracting Node.js runtime...';
    if OfflineMode then begin
      ExtractTemporaryFile('{#NodeZipName}');
      ZipSrc := ExpandConstant('{tmp}\{#NodeZipName}');
    end else begin
      // DownloadPage stored it at {tmp}\{#NodeZipName}
      ZipSrc := ExpandConstant('{tmp}\{#NodeZipName}');
    end;

    if not FileExists(ZipSrc) then begin
      MsgBox('Node.js runtime archive not found at ' + ZipSrc, mbError, MB_OK);
      Abort;
    end;

    // 2. Extract and relocate
    if not ExtractNodeZip(ZipSrc, RuntimeDir) then begin
      MsgBox('Failed to extract Node.js runtime.', mbError, MB_OK);
      Abort;
    end;
    if not RelocateNodeRuntime(RuntimeDir) then begin
      MsgBox('Failed to relocate Node.js runtime directory.', mbError, MB_OK);
      Abort;
    end;

    // 3. Emit settings.js (tokens substituted)
    WizardForm.StatusLabel.Caption := 'Writing SmartBAS settings...';
    WriteSettingsJs();

    // 4. Write license.json and burn activation into registry
    WizardForm.StatusLabel.Caption := 'Writing license activation...';
    if not UpgradeMode then begin
      Key := Uppercase(Trim(EditLicenseKey.Text));
      MachineGuid := GetMachineGuid();
      WriteLicenseJson();
      MarkKeyAsActivated(Key, MachineGuid);
      BindKeyToMachine(Key);
    end;
  end;
end;

// -----------------------------------------------------------------------------
// Uninstaller notice
// -----------------------------------------------------------------------------
procedure CurUninstallStepChanged(CurUninstallStep: TUninstallStep);
begin
  if CurUninstallStep = usPostUninstall then begin
    MsgBox('SmartBAS has been removed.' + #13#10 + #13#10 +
           'Your flow data has been preserved at ' + ExpandConstant('{app}') + '\data\',
           mbInformation, MB_OK);
  end;
end;
