Add-Type -AssemblyName System.Drawing
$src = 'e:\smartbas\build\assets\logo_source.png'
$dst = 'e:\smartbas\build\app\packages\node_modules\@node-red\editor-client\public\smartbas\header.png'
$logo = [System.Drawing.Image]::FromFile($src)
# Node-RED header is ~40px tall. Keep aspect ratio.
$targetH = 40
$targetW = [int]($logo.Width * ($targetH / $logo.Height))
$bmp = New-Object System.Drawing.Bitmap $targetW, $targetH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode = 'HighQuality'
$g.Clear([System.Drawing.Color]::Transparent)
$g.DrawImage($logo, 0, 0, $targetW, $targetH)
$g.Dispose()
$bmp.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose()
$logo.Dispose()
Write-Host "Wrote $dst ($targetW x $targetH)"
