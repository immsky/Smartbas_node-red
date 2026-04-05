# SmartBAS BMS — Installer Build Guide

This guide shows how to compile the SmartBAS BMS Windows Setup.exe from
[SmartBAS_Setup.iss](SmartBAS_Setup.iss). You will produce two variants from
one source file:

| Variant        | Output                         | Size   | Internet at install |
| -------------- | ------------------------------ | ------ | ------------------- |
| Online         | `SmartBAS_Setup_Online.exe`    | ~4 MB  | Required            |
| Offline        | `SmartBAS_Setup_Offline.exe`   | ~55 MB | Not required        |

---

## 1. Required Directory Layout

Arrange the `build/` directory exactly like this before running `iscc.exe`:

```
build/
├── SmartBAS_Setup.iss
├── BUILD.md
├── assets/
│   ├── smartbas.ico          (app icon)
│   ├── banner.bmp            (164 x 314 px, 24-bit BMP — wizard left panel)
│   ├── smallbanner.bmp       (55 x 58 px, 24-bit BMP — wizard top-right)
│   ├── LICENSE.txt           (EULA text shown on license page)
│   └── settings.template.js  (Node-RED settings template — tokens replaced at install)
├── tools/
│   ├── nssm.exe              (NSSM 2.24 64-bit from https://nssm.cc)
│   └── healthcheck.ps1
├── runtime/
│   └── node-v20.19.0-win-x64.zip   (OFFLINE build only)
└── app/                              (your compiled SmartBAS forked Node-RED build)
    ├── package.json
    ├── settings.js
    └── node_modules/
        └── ...
```

---

## 2. One-time Setup

1. **Install Inno Setup 6.3 or later** from https://jrsoftware.org/isdl.php.
   Add the install directory (typically `C:\Program Files (x86)\Inno Setup 6`)
   to your `PATH` so `iscc.exe` is on the command line.
2. **Download NSSM 2.24 (64-bit)** from https://nssm.cc/release/nssm-2.24.zip
   and copy `win64\nssm.exe` into [build/tools/](tools/).
3. **Compile your SmartBAS app.** Copy the complete forked Node-RED build
   (including `node_modules/`) into [build/app/](app/).
4. **Place branding assets** in [build/assets/](assets/):
   - `smartbas.ico` — multi-size icon (16/32/48/256)
   - `banner.bmp` — 164×314 24-bit BMP
   - `smallbanner.bmp` — 55×58 24-bit BMP
5. **For offline builds only:** download the Node.js 20 LTS portable zip from
   https://nodejs.org/dist/v20.19.0/node-v20.19.0-win-x64.zip and place it in
   [build/runtime/](runtime/).
6. **Update the SHA-256** of the Node.js zip inside the `.iss` file. Replace
   the placeholder `NodeZipSHA256` value with the real hash from
   https://nodejs.org/dist/v20.19.0/SHASUMS256.txt (line that ends in
   `node-v20.19.0-win-x64.zip`).

---

## 3. Patch Third-Party Modules

The `node-red-dashboard` and `@flowfuse/node-red-dashboard` npm packages
cannot be forked in-place, so their branding is overlaid post-install by
[build/patch-modules.js](patch-modules.js). This runs automatically as
a `postinstall` hook when you install dependencies, but you can also
re-run it manually:

```bat
npm run patch-modules
```

The script is idempotent — it backs up originals as `*.orig` on first
run and is safe to re-run after every `npm install`. It:

- Rewrites "Node-RED Dashboard" → "SmartBAS BMS Dashboard" in the
  dashboard's server-side `ui.js`, locale files, compiled HTML/JS
- Injects SmartBAS welcome-page theme CSS into the dashboard index
- Replaces the dashboard's 64/120/192 px icons with the SmartBAS glyph
- Rewrites FlowFuse Dashboard title + base64 favicon to SmartBAS

---

## 4. Compile the Installers

From the `build/` directory:

```bat
:: Online variant (downloads Node.js at install time, ~4 MB output)
iscc SmartBAS_Setup.iss

:: Offline variant (bundles Node.js zip, ~55 MB output)
iscc /DOFFLINE_BUILD SmartBAS_Setup.iss
```

Both EXEs land in `build\output\`.

---

## 5. Optional — Code Signing

```bat
signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 ^
  /f your_cert.pfx /p your_password ^
  output\SmartBAS_Setup_Online.exe

signtool sign /fd SHA256 /tr http://timestamp.digicert.com /td SHA256 ^
  /f your_cert.pfx /p your_password ^
  output\SmartBAS_Setup_Offline.exe
```

---

## 6. Issuing More License Keys

License keys are embedded directly in the compiled binary — there is no
external database, INI, or sidecar file.

1. Open [SmartBAS_Setup.iss](SmartBAS_Setup.iss).
2. Find the `ValidKeys` function in the `[Code]` section.
3. Increase the `SetArrayLength(K, 50)` count and append new keys:
   ```pascal
   SetArrayLength(K, 51);
   K[50] := 'SMBAS-NEW1-NEW2-NEW3-NEW4';
   ```
4. Recompile both installer variants.

Keys must match the regex `^SMBAS-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$`.

---

## 7. Testing Checklist

Run each of these scenarios on a clean Windows 10/11 VM:

- [ ] **Fresh install** — enter a valid unused key, verify service starts,
      confirm `http://localhost:1880` loads SmartBAS editor.
- [ ] **License validation** — enter malformed key → red error shown, Next
      stays disabled.
- [ ] **Used-key rejection** — install with key A, uninstall, re-run installer
      with the same key A → "already activated" message appears, Next stays
      disabled.
- [ ] **Used key on second machine** — copy activation registry entry to
      another machine (or reuse the key there) → same rejection behavior.
- [ ] **Offline mode** — disconnect network, run online installer → it falls
      back with a notice. Then run offline installer → completes normally.
- [ ] **Port conflict** — start another process on port 1880, run installer
      → port page suggests next free port.
- [ ] **Upgrade path** — over an existing install: license page is skipped,
      `data/` is backed up to `data_backup_<timestamp>/`, service restarts.
- [ ] **Uninstall** — service stops & is removed, firewall rule removed,
      `C:\SmartBAS\data\` is preserved, `HKLM\SOFTWARE\SmartBAS\Activations`
      registry tree is preserved.
- [ ] **Health check** — Finish page "Run post-install health check" runs
      and writes `C:\SmartBAS\logs\install_health.log` with all 4 checks PASS.

---

## 8. Troubleshooting

| Symptom                              | Fix                                                       |
| ------------------------------------ | --------------------------------------------------------- |
| `iscc` not recognized                | Add Inno Setup install folder to PATH                     |
| SHA-256 mismatch on Node.js zip      | Update `NodeZipSHA256` in the `.iss` file                 |
| Service stays in "Paused" state      | Check `C:\SmartBAS\logs\error.log` and run `healthcheck.ps1` manually |
| Re-install rejects all 50 keys       | Check `HKLM\SOFTWARE\SmartBAS\Activations` — prior test runs consumed keys |
| `Expand-Archive` fails               | Requires Win10 1803+; use offline variant on older hosts  |
