# =============================================================================
# SmartBAS BMS — Post-Install Health Check
# -----------------------------------------------------------------------------
# Verifies:
#   1. Windows service 'SmartBAS' reaches Running state (timeout 30s)
#   2. HTTP GET http://localhost:<Port> returns 200 OK
#   3. C:\SmartBAS\license.json exists and is readable
#   4. hostId in license.json matches current MachineGuid
#
# Exit codes: 0 = all pass, 1 = any failure
# Log file:   <InstallRoot>\logs\install_health.log
# =============================================================================

param(
    [Parameter(Mandatory=$true)] [int]    $Port,
    [Parameter(Mandatory=$true)] [string] $InstallRoot
)

$ErrorActionPreference = 'Continue'
$logDir  = Join-Path $InstallRoot 'logs'
$logFile = Join-Path $logDir 'install_health.log'
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$overall = $true

function Write-Log {
    param([string]$Level, [string]$Message)
    $stamp = (Get-Date).ToString('yyyy-MM-ddTHH:mm:ss')
    $line  = "[$stamp] [$Level] $Message"
    Write-Host $line
    Add-Content -Path $logFile -Value $line
}

function Check {
    param([string]$Name, [bool]$Ok, [string]$Detail)
    if ($Ok) {
        Write-Log 'PASS' "$Name - $Detail"
    } else {
        Write-Log 'FAIL' "$Name - $Detail"
        $script:overall = $false
    }
}

Write-Log 'INFO' "=== SmartBAS health check started ==="
Write-Log 'INFO' "InstallRoot=$InstallRoot  Port=$Port"

# --- 1. Service status -------------------------------------------------------
$svcOk      = $false
$svcDetail  = 'service not found'
$deadline   = (Get-Date).AddSeconds(30)
while ((Get-Date) -lt $deadline) {
    $svc = Get-Service -Name 'SmartBAS' -ErrorAction SilentlyContinue
    if ($null -eq $svc) {
        $svcDetail = 'service SmartBAS not registered'
        break
    }
    if ($svc.Status -eq 'Running') {
        $svcOk = $true
        $svcDetail = 'service is Running'
        break
    }
    Start-Sleep -Seconds 1
}
if (-not $svcOk -and $svcDetail -eq 'service not found') {
    $svc = Get-Service -Name 'SmartBAS' -ErrorAction SilentlyContinue
    if ($svc) { $svcDetail = "service status=$($svc.Status) after 30s" }
}
Check -Name 'Service Running' -Ok $svcOk -Detail $svcDetail

# --- 2. HTTP probe -----------------------------------------------------------
$httpOk     = $false
$httpDetail = 'no response'
# Give Node-RED a moment to bind the port after service Running
Start-Sleep -Seconds 3
try {
    $resp = Invoke-WebRequest -Uri "http://localhost:$Port" -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop
    if ($resp.StatusCode -eq 200) {
        $httpOk = $true
        $httpDetail = "HTTP 200 on port $Port"
    } else {
        $httpDetail = "HTTP $($resp.StatusCode) on port $Port"
    }
} catch {
    $httpDetail = "request failed: $($_.Exception.Message)"
}
Check -Name 'HTTP Endpoint' -Ok $httpOk -Detail $httpDetail

# --- 3. license.json exists --------------------------------------------------
$licPath = Join-Path $InstallRoot 'license.json'
$licOk = Test-Path $licPath
Check -Name 'License File'   -Ok $licOk -Detail $licPath

# --- 4. hostId matches MachineGuid ------------------------------------------
$hostOk = $false; $hostDetail = 'license.json missing'
if ($licOk) {
    try {
        $lic = Get-Content -Raw -Path $licPath | ConvertFrom-Json
        $currentGuid = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Cryptography' -Name MachineGuid).MachineGuid
        if ($lic.hostId -eq $currentGuid) {
            $hostOk = $true
            $hostDetail = "hostId matches MachineGuid"
        } else {
            $hostDetail = "hostId mismatch (license=$($lic.hostId) machine=$currentGuid)"
        }
    } catch {
        $hostDetail = "error reading license: $($_.Exception.Message)"
    }
}
Check -Name 'Host Binding'   -Ok $hostOk -Detail $hostDetail

# --- summary -----------------------------------------------------------------
if ($overall) {
    Write-Log 'INFO' '=== Health check PASSED ==='
    exit 0
} else {
    Write-Log 'INFO' '=== Health check FAILED ==='
    exit 1
}
