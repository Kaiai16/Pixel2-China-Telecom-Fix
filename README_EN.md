# Pixel 2 / 2XL — China Telecom Fix

🌐 [中文](README.md) | English

> Enable China Telecom (CT) 4G LTE on Google Pixel 2 / 2XL with a single Magisk module.

## What This Does

Google Pixel 2 stock firmware is missing modem config files (mbn) for Chinese carriers. This guide uses a community Magisk module to add carrier configs for China Telecom, China Mobile, and China Unicom — enabling stable 4G LTE and VoLTE.

**Tested on:** Pixel 2 (walleye), Android 11, Magisk 25.2, China Telecom SIM

## Prerequisites

- Google Pixel 2 (walleye) or Pixel 2 XL (taimen)
- Unlocked Bootloader
- Magisk installed (tested: v25.2)
- Android 10 or 11

## Installation

### Option A: ADB (Recommended)

```bash
# 1. Clone the module
git clone https://github.com/stanislawrogasik/Pixel2XL-VoLTE-VoWiFi
cd Pixel2XL-VoLTE-VoWiFi

# 2. Package as zip
zip -r pixel2_volte.zip . -x "./QPSTMethod/*" "./LICENSE" "./README.md" "./changelog.md" "./update.json" "./.git/*"

# 3. Push to phone
adb push pixel2_volte.zip /sdcard/Download/

# 4. Install via Magisk
adb shell "su -c 'magisk --install-module /sdcard/Download/pixel2_volte.zip'"

# 5. Reboot
adb reboot
```

### Option B: Magisk Manager UI

1. Download the repo as zip
2. Transfer to phone
3. Magisk Manager → Modules → Install from storage → select zip
4. Reboot

## ⚠️ Required After Install: Clean Up system.prop Conflicts

The original module's `system.prop` contains properties from other devices that cause **WiFi and cellular signal to repeatedly disconnect** on Pixel 2. You must remove these lines after installation:

```bash
# View current system.prop
adb shell "su -c 'cat /data/adb/modules/Pixel2VolteVoWiFi/system.prop'"

# Remove the 4 conflicting lines (iwlan and ims_volte_enable)
adb shell "su -c 'sed -i \"/persist.dbg.ims_volte_enable/d;/persist.data.iwlan/d\" /data/adb/modules/Pixel2VolteVoWiFi/system.prop'"

# Delete stale persist properties
adb shell "su -c 'rm /data/property/persistent_properties'"

# Clear modem cache
adb shell "su -c 'rm -rf /data/vendor/radio/* /data/vendor/modem_fdr/*'"

# Reboot
adb reboot
```

Properties to remove:
- `persist.dbg.ims_volte_enable=1`
- `persist.data.iwlan.enable=true`
- `persist.data.iwlan=1`
- `persist.data.iwlan.ipsec.ap=1`

**Why deleting `persistent_properties` alone isn't enough:** Magisk re-injects properties from the module's `system.prop` on every boot. You must remove them from the source file, otherwise the issue will recur after reboot.

## Verify

```bash
# Should show "LTE"
adb shell "getprop gsm.network.type"

# Should show "CHN-CT"
adb shell "getprop gsm.operator.alpha"

# These should be empty (no output)
adb shell "getprop persist.dbg.ims_volte_enable"
adb shell "getprop persist.data.iwlan"
```

Or dial `*#*#4636#*#*` → Phone Information → check IMS Service Status.

## How It Works

The module uses Magisk's `.replace` to fully replace `/vendor/mbn/mcfg/configs/mcfg_sw/`, swapping the stock 26 NA/EU carrier configs with 160+ worldwide configs (including China CT/CMCC/CU). The mbn files are extracted from crDroid ROM and are compatible with Pixel 2's Snapdragon 835 modem.

## Supported Chinese Carriers

| Carrier | Directory | Features |
|---------|-----------|----------|
| China Telecom (CT) | `china/ct/` | LTE + VoLTE |
| China Mobile (CMCC) | `china/cmcc/` | LTE + VoLTE |
| China Unicom (CU) | `china/cu/` | LTE + VoLTE |

## FAQ

**Will this brick my phone?**
No. It only replaces carrier config files, not modem firmware. Remove the module via Magisk and reboot to restore.

**Do I need to reinstall after OTA updates?**
Possibly. Check network status after updates and reinstall if needed.

**Does China Mobile / China Unicom still work?**
Yes, even better — VoLTE is now available for all three carriers.

**WiFi or signal unstable after install?**
This is caused by conflicting properties in the module's `system.prop`. See the "Required After Install" section above to clean them up.

## Credits

- [stanislawrogasik/Pixel2XL-VoLTE-VoWiFi](https://github.com/stanislawrogasik/Pixel2XL-VoLTE-VoWiFi) — Original Magisk module
- IonutGherman @ XDA — mbn extraction from crDroid ROM
- [somin.n @ XDA](https://xdaforums.com/t/guide-enable-volte-for-unsupported-carriers.3892659/) — VoLTE guide

## License

[MIT](LICENSE)
