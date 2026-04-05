# Builds banner.bmp / smallbanner.bmp / smartbas.ico from logo_source.png
# by compositing onto properly-sized canvases with padding.

Add-Type -AssemblyName System.Drawing

$assetsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $assetsDir

$logoPath = Join-Path $assetsDir 'logo_source.png'
if (-not (Test-Path $logoPath)) { throw "Missing $logoPath" }

$logo = [System.Drawing.Image]::FromFile($logoPath)
$logoW = $logo.Width; $logoH = $logo.Height
Write-Host "Logo source: $logoW x $logoH"

function Fit-Rect {
    # Compute centered destination rect that fits $srcW x $srcH into $maxW x $maxH preserving aspect.
    param([int]$srcW, [int]$srcH, [int]$maxW, [int]$maxH, [int]$padX, [int]$padY)
    $availW = $maxW - 2*$padX
    $availH = $maxH - 2*$padY
    $ratio = [Math]::Min($availW / $srcW, $availH / $srcH)
    $w = [int]($srcW * $ratio)
    $h = [int]($srcH * $ratio)
    $x = [int](($maxW - $w) / 2)
    $y = [int](($maxH - $h) / 2)
    return New-Object System.Drawing.Rectangle $x, $y, $w, $h
}

function Save-Bmp24 {
    # Saves as 24-bit uncompressed BMP (BMP3 — what Inno Setup expects)
    param([System.Drawing.Bitmap]$bmp, [string]$path)
    $out = New-Object System.Drawing.Bitmap $bmp.Width, $bmp.Height, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($out)
    $g.Clear([System.Drawing.Color]::White)
    $g.DrawImage($bmp, 0, 0, $bmp.Width, $bmp.Height)
    $g.Dispose()
    $out.Save($path, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $out.Dispose()
}

# -----------------------------------------------------------------------------
# 1. banner.bmp  — 164 x 314 wizard left panel
#    Layout: white background, logo fitted to top portion, tagline space below
# -----------------------------------------------------------------------------
$bannerW = 164; $bannerH = 314
$banner = New-Object System.Drawing.Bitmap $bannerW, $bannerH, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($banner)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode = 'HighQuality'
$g.Clear([System.Drawing.Color]::White)
# Fit logo into upper 60% with 8px padding
$logoRect = Fit-Rect -srcW $logoW -srcH $logoH -maxW $bannerW -maxH ([int]($bannerH * 0.60)) -padX 8 -padY 8
$g.DrawImage($logo, $logoRect)
# Tagline / version at bottom
$tagFont = New-Object System.Drawing.Font 'Segoe UI', 9, ([System.Drawing.FontStyle]::Bold)
$smallFont = New-Object System.Drawing.Font 'Segoe UI', 7, ([System.Drawing.FontStyle]::Regular)
$gold = [System.Drawing.Color]::FromArgb(212, 160, 23)
$dark = [System.Drawing.Color]::FromArgb(60, 60, 60)
$goldBrush = New-Object System.Drawing.SolidBrush $gold
$darkBrush = New-Object System.Drawing.SolidBrush $dark
$sf = New-Object System.Drawing.StringFormat; $sf.Alignment = 'Center'; $sf.LineAlignment = 'Near'
$g.DrawString('Building Automation', $tagFont, $goldBrush,
    (New-Object System.Drawing.RectangleF 0, ($bannerH * 0.68), $bannerW, 20), $sf)
$g.DrawString('Platform', $tagFont, $goldBrush,
    (New-Object System.Drawing.RectangleF 0, ($bannerH * 0.73), $bannerW, 20), $sf)
$g.DrawString('Version 1.0.0', $smallFont, $darkBrush,
    (New-Object System.Drawing.RectangleF 0, ($bannerH * 0.88), $bannerW, 16), $sf)
# Gold bottom accent bar
$g.FillRectangle($goldBrush, 0, $bannerH - 4, $bannerW, 4)
$g.Dispose()
$banner.Save((Join-Path $assetsDir 'banner.bmp'), [System.Drawing.Imaging.ImageFormat]::Bmp)
$banner.Dispose()
Write-Host "Wrote banner.bmp (164 x 314)"

# -----------------------------------------------------------------------------
# 2. smallbanner.bmp  — 55 x 58 wizard top-right
#    Crop out just the green-building circle glyph from the right side of the logo
# -----------------------------------------------------------------------------
$smallW = 55; $smallH = 58
$small = New-Object System.Drawing.Bitmap $smallW, $smallH, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$g = [System.Drawing.Graphics]::FromImage($small)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'
$g.Clear([System.Drawing.Color]::White)
# The glyph (circle with green buildings) is roughly in the right 40% of the source.
# Crop roughly: x from 58% to 100%, y from 5% to 90%
$cropX = [int]($logoW * 0.58)
$cropY = [int]($logoH * 0.05)
$cropW = [int]($logoW * 0.42)
$cropH = [int]($logoH * 0.85)
$destRect = Fit-Rect -srcW $cropW -srcH $cropH -maxW $smallW -maxH $smallH -padX 2 -padY 2
$srcRect = New-Object System.Drawing.Rectangle $cropX, $cropY, $cropW, $cropH
$g.DrawImage($logo, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()
$small.Save((Join-Path $assetsDir 'smallbanner.bmp'), [System.Drawing.Imaging.ImageFormat]::Bmp)
$small.Dispose()
Write-Host "Wrote smallbanner.bmp (55 x 58)"

# -----------------------------------------------------------------------------
# 3. smartbas.ico  — multi-size (16/32/48/256)
#    Use the cropped glyph on a transparent background
# -----------------------------------------------------------------------------
$sizes = @(256, 48, 32, 16)
$pngs = @()
foreach ($s in $sizes) {
    $b = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.SmoothingMode = 'AntiAlias'
    $g.InterpolationMode = 'HighQualityBicubic'
    $g.PixelOffsetMode = 'HighQuality'
    $g.Clear([System.Drawing.Color]::Transparent)
    # Draw the cropped glyph centered, fitted with tight padding
    $pad = [Math]::Max(1, [int]($s * 0.04))
    $destRect = Fit-Rect -srcW $cropW -srcH $cropH -maxW $s -maxH $s -padX $pad -padY $pad
    $srcRect = New-Object System.Drawing.Rectangle $cropX, $cropY, $cropW, $cropH
    $g.DrawImage($logo, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $tmp = Join-Path $assetsDir ("_ico_$s.png")
    $b.Save($tmp, [System.Drawing.Imaging.ImageFormat]::Png)
    $b.Dispose()
    $pngs += $tmp
}
# Write multi-size ICO container
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
Write-Host "Wrote smartbas.ico"

$logo.Dispose()
Write-Host "Done."
