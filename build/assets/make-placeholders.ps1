# Generates placeholder branding assets for the SmartBAS installer.
# Produces 24-bit BMPs (BMP3 format Inno Setup accepts) and a multi-size .ico.
# Re-run to regenerate.

Add-Type -AssemblyName System.Drawing

$assetsDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $assetsDir

function New-Gradient-Bmp {
    param([int]$Width, [int]$Height, [string]$Path, [string]$Text, [int]$FontSize)
    $bmp = New-Object System.Drawing.Bitmap $Width, $Height, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    # Dark charcoal -> gold gradient (SmartBAS colors)
    $rect = New-Object System.Drawing.Rectangle 0, 0, $Width, $Height
    $c1 = [System.Drawing.Color]::FromArgb(28, 28, 28)      # #1c1c1c
    $c2 = [System.Drawing.Color]::FromArgb(212, 160, 23)    # #D4A017
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush $rect, $c1, $c2, 90.0
    $g.FillRectangle($brush, $rect)
    # Text
    $font = New-Object System.Drawing.Font 'Segoe UI', $FontSize, ([System.Drawing.FontStyle]::Bold)
    $textBrush = [System.Drawing.Brushes]::White
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = 'Center'
    $sf.LineAlignment = 'Center'
    $textRect = New-Object System.Drawing.RectangleF 0, 0, $Width, $Height
    $g.DrawString($Text, $font, $textBrush, $textRect, $sf)
    $g.Dispose()
    $bmp.Save($Path, [System.Drawing.Imaging.ImageFormat]::Bmp)
    $bmp.Dispose()
    Write-Host "Wrote $Path ($Width x $Height)"
}

# Wizard left panel
New-Gradient-Bmp -Width 164 -Height 314 -Path 'banner.bmp' -Text "SmartBAS`nBMS" -FontSize 16
# Wizard header strip
New-Gradient-Bmp -Width 55 -Height 58 -Path 'smallbanner.bmp' -Text "SB" -FontSize 20

# --- ICO ---------------------------------------------------------------------
# Build a 256x256 source image, then encode a multi-size .ico (16/32/48/256)
$sizes = @(256, 48, 32, 16)
$pngs = @()
foreach ($s in $sizes) {
    $b = New-Object System.Drawing.Bitmap $s, $s, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($b)
    $g.SmoothingMode = 'AntiAlias'
    $g.TextRenderingHint = 'AntiAliasGridFit'
    # Round dark bg with gold border
    $g.Clear([System.Drawing.Color]::Transparent)
    $bg = [System.Drawing.Color]::FromArgb(28, 28, 28)
    $gold = [System.Drawing.Color]::FromArgb(212, 160, 23)
    $bgBrush = New-Object System.Drawing.SolidBrush $bg
    $goldPen = New-Object System.Drawing.Pen $gold, ([math]::Max(1, $s/32))
    $g.FillEllipse($bgBrush, 1, 1, $s-2, $s-2)
    $g.DrawEllipse($goldPen, 1, 1, $s-2, $s-2)
    # "SB" monogram
    $fontSize = [math]::Max(6, [int]($s * 0.42))
    $font = New-Object System.Drawing.Font 'Segoe UI', $fontSize, ([System.Drawing.FontStyle]::Bold)
    $goldBrush = New-Object System.Drawing.SolidBrush $gold
    $sf = New-Object System.Drawing.StringFormat
    $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
    $rect = New-Object System.Drawing.RectangleF 0, 0, $s, $s
    $g.DrawString('SB', $font, $goldBrush, $rect, $sf)
    $g.Dispose()
    $tmpPath = Join-Path $assetsDir ("_icon_$s.png")
    $b.Save($tmpPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $b.Dispose()
    $pngs += $tmpPath
}

# Assemble ICO container manually from the PNGs
$icoPath = Join-Path $assetsDir 'smartbas.ico'
$fs = [System.IO.File]::Create($icoPath)
$bw = New-Object System.IO.BinaryWriter $fs
# ICONDIR header: reserved(2)=0, type(2)=1, count(2)=N
$bw.Write([UInt16]0); $bw.Write([UInt16]1); $bw.Write([UInt16]$pngs.Count)
# Compute entries
$offset = 6 + (16 * $pngs.Count)
$imgData = @()
for ($i = 0; $i -lt $pngs.Count; $i++) {
    $bytes = [System.IO.File]::ReadAllBytes($pngs[$i])
    $imgData += ,$bytes
    $dim = $sizes[$i]
    $w = if ($dim -eq 256) { 0 } else { $dim }  # 256 is encoded as 0
    $h = $w
    # ICONDIRENTRY: w(1), h(1), colors(1), reserved(1), planes(2), bpp(2), size(4), offset(4)
    $bw.Write([byte]$w); $bw.Write([byte]$h); $bw.Write([byte]0); $bw.Write([byte]0)
    $bw.Write([UInt16]1); $bw.Write([UInt16]32)
    $bw.Write([UInt32]$bytes.Length); $bw.Write([UInt32]$offset)
    $offset += $bytes.Length
}
foreach ($d in $imgData) { $bw.Write($d) }
$bw.Close(); $fs.Close()
foreach ($p in $pngs) { Remove-Item -Force $p }
Write-Host "Wrote smartbas.ico (256/48/32/16)"
