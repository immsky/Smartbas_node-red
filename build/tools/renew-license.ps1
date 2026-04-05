# =============================================================================
# SmartBAS BMS — Annual Maintenance License Renewal Tool
# -----------------------------------------------------------------------------
# Run as ADMINISTRATOR. Extends the current SmartBAS license by 365 days.
#
# Usage:  Start Menu -> SmartBAS BMS -> Renew SmartBAS License
#         or: powershell -File C:\SmartBAS\tools\renew-license.ps1
# =============================================================================

$ErrorActionPreference = 'Stop'
$installRoot = 'C:\SmartBAS'
$licensePath = Join-Path $installRoot 'license.json'
$regBase     = 'HKLM:\SOFTWARE\SmartBAS'
$regRenewals = 'HKLM:\SOFTWARE\SmartBAS\Renewals'

# ---- Maintenance renewal key pool (50 pre-generated keys) -------------------
$RenewalKeys = @(
    'SMREN-R4XQ-PM82-LC6V-ZH90', 'SMREN-T2KB-NW45-DJ8F-YR31', 'SMREN-G7PS-CL63-HN2X-MK58',
    'SMREN-B5UF-QE17-WA9T-EP74', 'SMREN-V1JD-MX38-KR6L-CQ25', 'SMREN-H8NA-TY50-BF4G-SW96',
    'SMREN-P3CL-DR92-UM7K-XN41', 'SMREN-Y6ZH-KB84-FT1E-JV53', 'SMREN-D9WQ-GN26-AP5R-LC78',
    'SMREN-M4FK-SV73-QH0B-NX19', 'SMREN-K7BR-XP48-EY2D-WG65', 'SMREN-Z1LN-JT96-CU3V-AM82',
    'SMREN-Q8VC-HD51-RK7F-TP40', 'SMREN-U3MG-BW29-LJ6X-EN17', 'SMREN-N5YK-FR83-SQ2T-DA54',
    'SMREN-C6EH-VB70-NG9P-MY36', 'SMREN-F2XT-WL45-KE1R-ZB98', 'SMREN-J9DP-QA62-BV4M-UC23',
    'SMREN-A4RK-NC87-XS8Y-LF15', 'SMREN-W1GT-MH34-PQ7J-TD69', 'SMREN-E5VB-KN91-RA3L-XC26',
    'SMREN-L8QY-FJ72-WE4K-NH57', 'SMREN-X2PD-CR58-UB6M-GV83', 'SMREN-I7TF-ZM19-NK5Q-WL40',
    'SMREN-S0NG-AV65-TX3H-CF92', 'SMREN-R9KQ-PM14-LC7V-ZH38', 'SMREN-T6KB-NW81-DJ3F-YR52',
    'SMREN-G3PS-CL27-HN9X-MK74', 'SMREN-B0UF-QE53-WA5T-EP19', 'SMREN-V7JD-MX90-KR2L-CQ86',
    'SMREN-H4NA-TY18-BF7G-SW43', 'SMREN-P1CL-DR64-UM3K-XN07', 'SMREN-Y9ZH-KB36-FT8E-JV21',
    'SMREN-D2WQ-GN75-AP1R-LC49', 'SMREN-M7FK-SV08-QH4B-NX62', 'SMREN-K0BR-XP91-EY6D-WG18',
    'SMREN-Z4LN-JT27-CU8V-AM53', 'SMREN-Q1VC-HD84-RK0F-TP95', 'SMREN-U6MG-BW62-LJ9X-EN34',
    'SMREN-N8YK-FR16-SQ5T-DA71', 'SMREN-C9EH-VB43-NG2P-MY80', 'SMREN-F5XT-WL78-KE4R-ZB61',
    'SMREN-J2DP-QA95-BV7M-UC46', 'SMREN-A7RK-NC30-XS1Y-LF82', 'SMREN-W4GT-MH67-PQ0J-TD93',
    'SMREN-E8VB-KN24-RA6L-XC59', 'SMREN-L1QY-FJ05-WE7K-NH86', 'SMREN-X5PD-CR91-UB9M-GV17',
    'SMREN-I0TF-ZM52-NK8Q-WL73', 'SMREN-S3NG-AV38-TX6H-CF24'
)

function Write-Header {
    Clear-Host
    Write-Host ""
    Write-Host "  =================================================" -ForegroundColor Yellow
    Write-Host "       SmartBAS BMS - Maintenance License Renewal"    -ForegroundColor Yellow
    Write-Host "  =================================================" -ForegroundColor Yellow
    Write-Host ""
}

function Test-Admin {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $pr = New-Object System.Security.Principal.WindowsPrincipal($id)
    return $pr.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

Write-Header

if (-not (Test-Admin)) {
    Write-Host "  ERROR: This tool must be run as Administrator." -ForegroundColor Red
    Write-Host "         Right-click the shortcut and choose 'Run as administrator'."
    Write-Host ""; Read-Host "  Press ENTER to exit"
    exit 1
}

if (-not (Test-Path $licensePath)) {
    Write-Host "  ERROR: No SmartBAS license found at $licensePath" -ForegroundColor Red
    Write-Host "         SmartBAS does not appear to be installed on this machine."
    Write-Host ""; Read-Host "  Press ENTER to exit"
    exit 1
}

# --- Load current license state ----------------------------------------------
try {
    $lic = Get-Content -Raw $licensePath | ConvertFrom-Json
} catch {
    Write-Host "  ERROR: Could not read license.json - $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""; Read-Host "  Press ENTER to exit"
    exit 1
}

$currentExpiry = [DateTime]::Parse($lic.expiresAt)
$today         = Get-Date

Write-Host "  Currently bound license:" -ForegroundColor White
Write-Host "    Key         :  $($lic.maskedKey)"
Write-Host "    Organization:  $($lic.organization)"
Write-Host "    Activated   :  $($lic.activatedAt)"
Write-Host "    Expires     :  $($lic.expiresAt)" -NoNewline
if ($today -gt $currentExpiry) {
    Write-Host "   (EXPIRED)" -ForegroundColor Red
} else {
    $daysLeft = [Math]::Ceiling(($currentExpiry - $today).TotalDays)
    Write-Host "   ($daysLeft days remaining)" -ForegroundColor Green
}
Write-Host ""

# --- Prompt for renewal key --------------------------------------------------
Write-Host "  Enter your maintenance renewal key:" -ForegroundColor White
Write-Host "  (Format: SMREN-XXXX-XXXX-XXXX-XXXX)" -ForegroundColor DarkGray
Write-Host ""
$input = Read-Host "  Renewal key"
$key = $input.Trim().ToUpper()

# Step 1: format check
if ($key -notmatch '^SMREN-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$') {
    Write-Host ""
    Write-Host "  X  Invalid format. Renewal keys must be SMREN-XXXX-XXXX-XXXX-XXXX" -ForegroundColor Red
    Write-Host ""; Read-Host "  Press ENTER to exit"; exit 1
}

# Step 2: key in pool?
if ($RenewalKeys -notcontains $key) {
    Write-Host ""
    Write-Host "  X  Invalid renewal key. Contact SmartBAS support." -ForegroundColor Red
    Write-Host ""; Read-Host "  Press ENTER to exit"; exit 1
}

# Step 3: already consumed?
if (-not (Test-Path $regRenewals)) {
    New-Item -Path $regRenewals -Force | Out-Null
}
$existing = Get-ItemProperty -Path $regRenewals -Name $key -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host ""
    Write-Host "  X  This renewal key has already been used." -ForegroundColor Red
    Write-Host "      Used on: $($existing.$key)" -ForegroundColor DarkGray
    Write-Host ""; Read-Host "  Press ENTER to exit"; exit 1
}

# --- Apply renewal: extend expiry by 365 days --------------------------------
# Extension anchors at whichever is later: today OR the current expiry date
# so renewing early doesn't shorten your remaining term.
$anchor = if ($today -gt $currentExpiry) { $today } else { $currentExpiry }
$newExpiry = $anchor.AddDays(365)
$newExpiryIso = $newExpiry.ToString("yyyy-MM-ddTHH:mm:ssZ")
$renewedAtIso = $today.ToString("yyyy-MM-ddTHH:mm:ssZ")
$machineGuid  = (Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid).MachineGuid

Write-Host ""
Write-Host "  Applying renewal..." -ForegroundColor Yellow

# Update license.json (preserve all fields, append renewal history)
if (-not $lic.PSObject.Properties.Name -contains 'renewalHistory') {
    $lic | Add-Member -MemberType NoteProperty -Name renewalHistory -Value @() -Force
}
$historyEntry = [pscustomobject]@{
    renewalKey     = $key
    maskedKey      = "SMREN-****-****-****-" + $key.Substring(21,4)
    renewedAt      = $renewedAtIso
    previousExpiry = $lic.expiresAt
    newExpiry      = $newExpiryIso
}
$lic.renewalHistory = @($lic.renewalHistory) + $historyEntry
$lic.expiresAt         = $newExpiryIso
$lic.maintenanceUntil  = $newExpiryIso
$lic | ConvertTo-Json -Depth 6 | Set-Content -Path $licensePath -Encoding UTF8

# Mark renewal key as consumed in registry
Set-ItemProperty -Path $regRenewals -Name $key -Value "$machineGuid|$renewedAtIso"

# Update ExpiresAt under HKLM\SOFTWARE\SmartBAS
Set-ItemProperty -Path $regBase -Name 'ExpiresAt'  -Value $newExpiryIso
Set-ItemProperty -Path $regBase -Name 'LastRenewal' -Value $renewedAtIso

# Log to install_health.log
$logDir = Join-Path $installRoot 'logs'
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Force -Path $logDir | Out-Null }
Add-Content -Path (Join-Path $logDir 'renewal.log') -Value `
    "[$renewedAtIso] Renewal applied. Key=SMREN-****-$($key.Substring(21,4))  Expiry=$newExpiryIso"

Write-Host ""
Write-Host "  +-----------------------------------------------+"       -ForegroundColor Green
Write-Host "  |  License renewed successfully.                |"       -ForegroundColor Green
Write-Host "  +-----------------------------------------------+"       -ForegroundColor Green
Write-Host ""
Write-Host "    Previous expiry:  $($historyEntry.previousExpiry)"
Write-Host "    New expiry:       $newExpiryIso"                         -ForegroundColor Green
Write-Host "    Renewed at:       $renewedAtIso"
Write-Host ""
Write-Host "  SmartBAS BMS service does not need to be restarted."
Write-Host ""
Read-Host "  Press ENTER to exit"
