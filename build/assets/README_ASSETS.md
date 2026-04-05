# Required Branding Assets

Drop these files into this folder before compiling. The installer will not
compile if any of the image files are missing.

| File               | Size        | Format          | Purpose                      |
| ------------------ | ----------- | --------------- | ---------------------------- |
| `smartbas.ico`     | multi-size  | Windows .ico    | Installer & app icon         |
| `banner.bmp`       | 164 × 314   | 24-bit BMP      | Wizard left panel            |
| `smallbanner.bmp`  | 55 × 58     | 24-bit BMP      | Wizard top-right header      |
| `LICENSE.txt`      | —           | UTF-8 text      | EULA (already included)      |
| `settings.template.js` | —       | JavaScript      | Node-RED settings (included) |

Generate the `.ico` from a 256×256 PNG using ImageMagick:
```bat
magick convert logo_256.png -define icon:auto-resize=256,48,32,16 smartbas.ico
```

Generate BMPs:
```bat
magick convert banner_src.png -resize 164x314! -type TrueColor BMP3:banner.bmp
magick convert small_src.png  -resize 55x58!   -type TrueColor BMP3:smallbanner.bmp
```

Inno Setup is strict about BMP format — use **BMP3** (24-bit, uncompressed).
