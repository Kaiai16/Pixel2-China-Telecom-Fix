# Pixel 2 / 2XL — 中国电信修复指南

🌐 中文 | [English](README_EN.md)

> 一个 Magisk 模块，让 Google Pixel 2 / 2XL 支持中国电信 4G LTE 上网。

## 这是什么

Google Pixel 2 原版固件缺少中国运营商的 modem 配置文件（mbn），导致插入电信卡后显示"无服务"或"仅限紧急呼叫"。本指南通过安装一个社区 Magisk 模块，补全中国电信、移动、联通的运营商配置，实现稳定的 4G LTE 和 VoLTE。

**实测环境：** Pixel 2 (walleye)，Android 11，Magisk 25.2，中国电信 SIM 卡

## 前提条件

- Google Pixel 2 (walleye) 或 Pixel 2 XL (taimen)
- 已解锁 Bootloader
- 已安装 Magisk（测试版本：v25.2）
- Android 10 或 11

## 安装步骤

### 方法一：ADB 命令行（推荐）

```bash
# 1. 下载模块
git clone https://github.com/stanislawrogasik/Pixel2XL-VoLTE-VoWiFi
cd Pixel2XL-VoLTE-VoWiFi

# 2. 打包为 zip
zip -r pixel2_volte.zip . -x "./QPSTMethod/*" "./LICENSE" "./README.md" "./changelog.md" "./update.json" "./.git/*"

# 3. 推送到手机
adb push pixel2_volte.zip /sdcard/Download/

# 4. 通过 Magisk 安装
adb shell "su -c 'magisk --install-module /sdcard/Download/pixel2_volte.zip'"

# 5. 重启
adb reboot
```

### 方法二：Magisk Manager 图形界面

1. 下载仓库 zip 文件
2. 传输到手机
3. 打开 Magisk Manager → 模块 → 从本地安装 → 选择 zip 文件
4. 重启手机

## ⚠️ 注意事项

**禁止手动设置 VoLTE 相关的 persist 属性！** 模块的 `system.prop` 已经包含了所有必要的属性配置。如果你手动执行了类似以下命令：

```bash
# ❌ 不要这样做
setprop persist.dbg.ims_volte_enable 1
setprop persist.radio.rat_on combine
setprop persist.data.iwlan.enable true
```

这些手动设置的 persist 属性会与模块冲突，导致 **WiFi 和蜂窝信号反复断连**。

如果已经误操作，修复方法：
```bash
# 删除 persist 属性文件（系统重启后自动重建）
adb shell "su -c 'rm /data/property/persistent_properties'"
# 清除 modem 缓存
adb shell "su -c 'rm -rf /data/vendor/radio/* /data/vendor/modem_fdr/*'"
# 重启
adb reboot
```

## 验证

```bash
# 应显示 LTE
adb shell "getprop gsm.network.type"

# 应显示 CHN-CT
adb shell "getprop gsm.operator.alpha"
```

或在拨号盘输入 `*#*#4636#*#*` → 手机信息 → 查看 IMS Service Status。

## 原理

该模块使用 Magisk 的 `.replace` 机制完全替换 `/vendor/mbn/mcfg/configs/mcfg_sw/` 目录，将原来只有 26 个北美/欧洲运营商配置替换为 160+ 个全球运营商配置（包含中国电信/移动/联通）。mbn 文件提取自 crDroid ROM，与 Pixel 2 的骁龙 835 (MSM8998) modem 完全兼容。

## 支持的中国运营商

| 运营商 | 目录 | 支持功能 |
|--------|------|----------|
| 中国电信 (CT) | `china/ct/` | LTE + VoLTE |
| 中国移动 (CMCC) | `china/cmcc/` | LTE + VoLTE |
| 中国联通 (CU) | `china/cu/` | LTE + VoLTE |

## 常见问题

**会变砖吗？**
不会。模块只替换运营商配置文件，不修改 modem 固件。通过 Magisk 删除模块重启即可恢复。

**系统更新后需要重新安装吗？**
可能需要。OTA 更新可能覆盖 vendor 分区，更新后检查网络状态，不正常就重新安装。

**移动/联通卡还能用吗？**
能，而且比之前更好 — 三大运营商都可以启用 VoLTE 高清通话。

**安装后 WiFi 或信号不稳定？**
参考上方"注意事项"，很可能是手动设置了 persist 属性导致冲突。删除 `/data/property/persistent_properties` 并清除 modem 缓存后重启即可。

## 致谢

- [stanislawrogasik/Pixel2XL-VoLTE-VoWiFi](https://github.com/stanislawrogasik/Pixel2XL-VoLTE-VoWiFi) — 原始 Magisk 模块作者
- IonutGherman @ XDA — 从 crDroid ROM 提取 mbn 文件
- [somin.n @ XDA](https://xdaforums.com/t/guide-enable-volte-for-unsupported-carriers.3892659/) — VoLTE 启用教程

## 许可证

[MIT](LICENSE)
