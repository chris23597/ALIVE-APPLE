# ALIVE APPLE — 100% FREE iPhone 16 Setup (Windows 11)

This guide gets ALIVE APPLE onto your iPhone 16 without spending a dollar.
No Mac required. No paid developer account. All free.

---

## How It Works

```
Your Windows PC                    GitHub (free)                Your iPhone 16
─────────────────                  ─────────────                ──────────────
Push code to repo      ──→    macOS runner builds IPA   ──→   Download IPA
                                    (free, 5 minutes)           Sideload via AltStore
                                                                App appears on home screen!
```

---

## STEP 1: Push your code to GitHub (FREE — 5 minutes)

1. **Create a free GitHub account** at https://github.com (if you don't have one)
2. **Create a new repository** — name it `ALIVE_APPLE` — make it **PUBLIC**
3. **Upload the project:**
   - Copy the entire `ALIVE_APPLE` folder from this flash drive to your Desktop
   - Open `GitHub Desktop` (free download) or use command line:
   ```bash
   cd C:\Users\chris\Desktop\ALIVE_APPLE
   git init
   git add .
   git commit -m "ALIVE APPLE for iPhone 16"
   git remote add origin https://github.com/YOUR_USERNAME/ALIVE_APPLE.git
   git push -u origin main
   ```

4. **The build starts automatically** — go to your repo on GitHub.com → click "Actions" tab
5. Wait ~5 minutes for the build to complete (orange dot turns green)

---

## STEP 2: Download the IPA from GitHub (FREE — 1 minute)

1. On your repo's GitHub page, click **Actions**
2. Click the latest successful build (green checkmark)
3. Scroll down to **Artifacts** → click `ALIVE_APPLE_iPhone16`
4. The **ALIVE_APPLE.ipa** file downloads to your PC

---

## STEP 3: Install AltStore on your iPhone (FREE — 10 minutes)

1. Download **AltServer** for Windows: https://altstore.io
2. Install and run AltServer on your Windows PC
3. **Plug your iPhone 16 into your PC via USB-C**
4. Make sure iTunes or Apple Devices app is installed (AltServer needs the driver)
   - Download from Microsoft Store: "Apple Devices" app (free)
5. Click the AltServer icon in your system tray (near the clock)
6. Select **Install AltStore → Your iPhone**
7. Enter your **Apple ID** (the same one you use on your iPhone — it's free)
8. AltStore appears on your iPhone home screen

---

## STEP 4: Install ALIVE APPLE on your iPhone (FREE — 2 minutes)

1. Open **AltStore** on your iPhone
2. Tap **My Apps** tab at the bottom
3. Tap the **+** button (top left)
4. Find and select `ALIVE_APPLE.ipa` (you can AirDrop it or email it to yourself)
5. Sign in with your Apple ID when prompted
6. ALIVE APPLE appears on your home screen!

---

## STEP 5: Import models and start using (2 minutes)

1. Plug this flash drive into your iPhone 16 (USB-C)
2. Open **ALIVE APPLE**
3. Go to **Models** tab → **Import from USB**
4. All 4 models import automatically
5. Start chatting — fully offline AI, zero cloud, zero cost

---

## IMPORTANT: App Refresh (every 7 days)

Free Apple IDs require apps to be re-signed every 7 days:

- Keep AltServer running on your PC
- Your iPhone must be on the same WiFi as your PC
- AltStore automatically refreshes the app in the background
- If it expires, just plug into PC and open AltStore → refresh

---

## Troubleshooting

| Problem | Fix |
|---------|-----|
| GitHub build fails | Check Actions tab for error log, fix code, push again |
| AltServer doesn't see iPhone | Install "Apple Devices" from Microsoft Store, try different USB port |
| "Untrusted Developer" on iPhone | Go to Settings → General → VPN & Device Management → Trust |
| App crashes on launch | Models not imported yet — import from USB first |
| App expires | Open AltStore on iPhone, refresh all apps while on same WiFi as PC |
