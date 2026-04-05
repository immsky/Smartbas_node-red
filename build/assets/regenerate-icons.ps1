# Regenerates smartbas.ico + dashboard icons from the transparent glyph.
Add-Type -AssemblyName System.Drawing

$glyph = 'e:\smartbas\build\assets\smartbas_glyph.png'
$assetsDir = 'e:\smartbas\build\assets'

function Resize-Transparent {
    param([string]$src, [int]$size, [string]$dst, [bool]$whiteBg = $false)
    $logo = [System.Drawing.Image]::FromFile($src)
    $bmp = New-Object System.Drawing.Bitmap $size, $size, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    if ($whiteBg) { $g.Clear([System.Drawing.Color]::White) } else { $g.Clear([System.Drawing.Color]::Transparent) }
    $pad = [Math]::Max(1, [int]($size * 0.03))
    $avail = $size - 2*$pad
    $ratio = [Math]::Min($avail / $logo.Width, $avail / $logo.Height)
    $w = [int]($logo.Width * $ratio); $h = [int]($logo.Height * $ratio)
    $x = [int](($size - $w) / 2); $y = [int](($size - $h) / 2)
    $g.DrawImage($logo, $x, $y, $w, $h)
    $g.Dispose()
    $bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    $logo.Dispose()
}

# --- smartbas.ico — multi-size, transparent background ---
$sizes = @(256, 64, 48, 32, 16)
$pngs = @()
foreach ($s in $sizes) {
    $tmp = Join-Path $assetsDir "_ico_$s.png"
    Resize-Transparent -src $glyph -size $s -dst $tmp
    $pngs += $tmp
}
$icoPath = Join-Path $assetsDir 'smartbas.ico'
$fs = [System.IO.File]::Create($icoPath)
$bw = New-Object System.IO.BinaryWriter $fs
$bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]$pngs.Count)
$offset = 6 + (16 * $pngs.Count)
$imgData = @()
for ($i = 0; $i -lt $pngs.Count; $i++) {
    $bytes = [System.IO.File]::ReadAllBytes($pngs[$i])
    $imgData += ,$bytes
    $dim = $sizes[$i]
    $w = if ($dim -eq 256) { 0 } else { $dim }
    $bw.Write([byte]$w); $bw.Write([byte]$w); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([UInt16]1); $bw.Write([UInt16]32)
    $bw.Write([UInt32]$bytes.Length); $bw.Write([UInt32]$offset)
    $offset += $bytes.Length
}
foreach ($d in $imgData) { $bw.Write($d) }
$bw.Close(); $fs.Close()
foreach ($p in $pngs) { Remove-Item -Force $p }
Write-Host "Wrote smartbas.ico (transparent, 16/32/48/64/256)"

# --- Dashboard icon sizes (PNG with white background since manifest expects it) ---
# We keep the glyph sharp and add a subtle white rounded bg for contrast.
Resize-Transparent -src $glyph -size 64  -dst (Join-Path $assetsDir 'dashboard-icon-64.png')  -whiteBg $true
Resize-Transparent -src $glyph -size 120 -dst (Join-Path $assetsDir 'dashboard-icon-120.png') -whiteBg $true
Resize-Transparent -src $glyph -size 192 -dst (Join-Path $assetsDir 'dashboard-icon-192.png') -whiteBg $true
Write-Host "Wrote dashboard-icon-{64,120,192}.png"
Write-Host "Done."
