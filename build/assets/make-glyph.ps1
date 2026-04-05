# Crops the circular building glyph from the SmartBAS logo, removes the white
# background (color-key transparency), and emits a master transparent PNG at
# 512x512. The installer uses this as the source for favicon.ico + dashboard
# icons + editor tab icon.
Add-Type -AssemblyName System.Drawing

$src = 'e:\smartbas\build\assets\logo_source.png'
$dst = 'e:\smartbas\build\assets\smartbas_glyph.png'

$logo = [System.Drawing.Image]::FromFile($src)
$logoW = $logo.Width; $logoH = $logo.Height

# The glyph (gold circle with green buildings) lives in roughly the right
# 42% of the source image — empirically: x 58%..100%, y 5%..95%.
$cropX = [int]($logoW * 0.58)
$cropY = [int]($logoH * 0.02)
$cropW = $logoW - $cropX
$cropH = [int]($logoH * 0.96)

# Stage 1: crop
$staged = New-Object System.Drawing.Bitmap $cropW, $cropH, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($staged)
$g.Clear([System.Drawing.Color]::Transparent)
$g.DrawImage($logo, 0, 0, (New-Object System.Drawing.Rectangle $cropX, $cropY, $cropW, $cropH), [System.Drawing.GraphicsUnit]::Pixel)
$g.Dispose()

# Stage 2: color-key white pixels to transparent (threshold-based)
# Any pixel whose R, G, B are ALL above $thr becomes fully transparent.
$thr = 240
$w = $staged.Width; $h = $staged.Height
$data = $staged.LockBits(
    (New-Object System.Drawing.Rectangle 0, 0, $w, $h),
    [System.Drawing.Imaging.ImageLockMode]::ReadWrite,
    [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$bytes = New-Object byte[] ($data.Stride * $h)
[System.Runtime.InteropServices.Marshal]::Copy($data.Scan0, $bytes, 0, $bytes.Length)
for ($i = 0; $i -lt $bytes.Length; $i += 4) {
    $b = $bytes[$i]; $gr = $bytes[$i+1]; $r = $bytes[$i+2]
    if (($r -ge $thr) -and ($gr -ge $thr) -and ($b -ge $thr)) {
        $bytes[$i+3] = 0       # alpha = 0 (transparent)
    }
}
[System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $data.Scan0, $bytes.Length)
$staged.UnlockBits($data)

# Stage 3: resize to 512x512 (square canvas) with aspect preserved
$final = New-Object System.Drawing.Bitmap 512, 512, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($final)
$g.SmoothingMode = 'AntiAlias'
$g.InterpolationMode = 'HighQualityBicubic'
$g.PixelOffsetMode = 'HighQuality'
$g.Clear([System.Drawing.Color]::Transparent)
$ratio = [Math]::Min(512.0 / $w, 512.0 / $h)
$fw = [int]($w * $ratio); $fh = [int]($h * $ratio)
$fx = [int]((512 - $fw) / 2); $fy = [int]((512 - $fh) / 2)
$g.DrawImage($staged, $fx, $fy, $fw, $fh)
$g.Dispose()

$final.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$final.Dispose()
$staged.Dispose()
$logo.Dispose()
Write-Host "Wrote $dst (512 x 512, transparent)"
