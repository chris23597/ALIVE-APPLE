# Install ALIVE APPLE on iPhone from Windows

## What is ready on this PC

| Piece | Status |
|--------|--------|
| IPA (unsigned CI) | Desktop `ALIVE_APPLE.ipa` + `exports/ALIVE_APPLE.ipa` |
| Sideloadly | Installed (`%LOCALAPPDATA%\Sideloadly\sideloadly.exe`) |
| Apple Mobile Device Support | Installed + service Running |
| Deployment target | **iOS 17.0+** (Swift Observation + SwiftData — hard requirement) |

## Why Sideloadly (not Xcode)

CI IPA is **unsigned**. Real iPhones need a signature. Sideloadly re-signs with **your free Apple ID** and installs over USB.

## Phone steps (do these on the iPhone)

1. Unlock the phone; stay on the home screen.  
2. Plug USB into the PC (data cable, not charge-only).  
3. When asked **Trust This Computer** → tap **Trust** → enter passcode.  
4. Settings → Privacy & Security → **Developer Mode** ON (if iOS 16+ and prompted).  
5. After install: Settings → General → VPN & Device Management → trust developer app.

## Sideloadly steps (PC)

1. Sideloadly should open with `ALIVE_APPLE.ipa`.  
2. Select your **iPhone** in the device dropdown (not empty).  
3. Enter **Apple ID** email + password (or app-specific password if 2FA).  
4. Options: leave default; for free ID expect **7-day** cert (re-sideload weekly).  
5. Click **Start** and wait until install completes.  
6. On phone: open **ALIVE APPLE** once; if blocked, trust the developer profile.

## If device not listed

- Unplug/replug; unlock; Trust again.  
- Confirm cable is data-capable.  
- Restart `Apple Mobile Device Service` (Services.msc).  
- Only one phone plugged if two show as unknown.

## Prefer newer IPA (iOS 16)

```powershell
powershell -File C:\Users\chris\CodeWhale\scripts\codewhale-alive-apple-phone-install.ps1 -DownloadOnly
```

Then open Sideloadly on the refreshed Desktop IPA.

## Limits (honest)

- Free Apple ID: app expires ~7 days without re-sign.  
- Paid Developer account ($99/yr): longer install + TestFlight path (still easier on Mac).  
- Phone must be **iOS 17 or newer** (Settings → General → About). Older OS cannot run this app.
