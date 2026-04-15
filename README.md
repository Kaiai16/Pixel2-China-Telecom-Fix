# Pixel 2 / 2XL 中国电信修复指南 | China Telecom Fix Guide

**让 Google Pixel 2 / 2XL 支持中国电信 4G LTE 上网**

**Enable China Telecom 4G LTE on Google Pixel 2 / 2XL**

---

## 问题描述 | Problem

Google Pixel 2 / 2XL 插入中国电信 SIM 卡后无法上网，显示"无服务"或"仅限紧急呼叫"。

Google Pixel 2 / 2XL cannot connect to China Telecom network. Shows "No Service" or "Emergency Calls Only" after inserting a China Telecom SIM card.

### 根本原因 | Root Cause

Google 官方固件只包含北美和部分欧洲运营商的 modem 配置文件（mbn），**完全没有中国运营商的配置**。中国电信是纯 4G LTE 网络（无 2G/3G 回落），必须有正确的 mbn 配置才能注册网络。

The stock firmware only includes modem config files (mbn) for NA/EU carriers. **China carrier configs are completely missing**. China Telecom requires proper mbn configs for LTE registration since it has no 2G/3G fallback.

---

## 解决方案 | Solution

使用 Magisk 模块替换 modem 运营商配置，补全中国三大运营商（电信/移动/联通）的 mbn 文件。

Install a Magisk module that replaces modem carrier configs, adding mbn files for all three Chinese carriers (CT/CMCC/CU).

### 前提条件 | Prerequisites

- Google Pixel 2 (walleye) 或 Pixel 2 XL (taimen)
- 已解锁 Bootloader
- 已安装 Magisk（测试版本：Magisk 25.2）
- Android 10 或 Android 11

### 安装步骤 | Installation

#### 方法一：ADB 命令行安装（推荐）

```bash
# 1. 下载模块
git clone https://github.com/stanislawrogasik/Pixel2XL-VoLTE-VoWiFi
cd Pixel2XL-VoLTE-VoWiFi

# 2. 打包为 zip（排除无关文件）
zip -r pixel2_volte.zip . -x "./QPSTMethod/*" "./LICENSE" "./README.md" "./changelog.md" "./update.json" "./.git/*"

# 3. 推送到手机
adb push pixel2_volte.zip /sdcard/Download/

# 4. 通过 Magisk 安装
adb shell "su -c 'magisk --install-module /sdcard/Download/pixel2_volte.zip'"

# 5. 重启
adb reboot
```

#### 方法二：Magisk Manager 图形界面安装

1. 下载仓库 zip 文件
2. 传输到手机
3. 打开 Magisk Manager → 模块 → 从本地安装 → 选择 zip 文件
4. 重启手机

### 验证是否成功 | Verify

```bash
# 检查网络类型（应显示 LTE）
adb shell "getprop gsm.network.type"

# 检查运营商（应显示 CHN-CT）
adb shell "getprop gsm.operator.alpha"

# 检查 VoLTE 状态
# 拨号盘输入 *#*#4636#*#* → 手机信息 → IMS Service Status
```

---

## 技术细节 | Technical Details

### 模块原理

该模块使用 Magisk 的 `.replace` 机制**完全替换** `/vendor/mbn/mcfg/configs/mcfg_sw/` 目录，将原来只有 26 个北美/欧洲运营商配置替换为包含 160+ 全球运营商的完整配置。

The module uses Magisk's `.replace` mechanism to **fully replace** the `/vendor/mbn/mcfg/configs/mcfg_sw/` directory, expanding from 26 NA/EU carrier configs to 160+ worldwide carrier configs.

### 支持的中国运营商

| 运营商 | 目录 | 支持功能 |
|--------|------|----------|
| 中国电信 (CT) | `china/ct/` | LTE + VoLTE |
| 中国移动 (CMCC) | `china/cmcc/` | LTE + VoLTE |
| 中国联通 (CU) | `china/cu/` | LTE + VoLTE |

### mbn 文件来源

mbn 文件提取自 **crDroid ROM**（基于 LineageOS 的第三方 ROM），这些文件来自高通开源 modem 配置库，与 Pixel 2 的骁龙 835 (MSM8998) modem 完全兼容。

The mbn files are extracted from **crDroid ROM** (based on LineageOS). These files come from Qualcomm's open-source modem config repository and are fully compatible with Pixel 2's Snapdragon 835 (MSM8998) modem.

### 为什么其他方案不行

| 方案 | 结果 | 原因 |
|------|------|------|
| 设置 VoLTE 系统属性 | ❌ 失败 | 只影响 Android 框架层，modem 底层不认 |
| 一加 7 的 mbn 替换 WildCard | ❌ 失败 | 骁龙 855 的 mbn 与骁龙 835 不兼容 |
| 修改 modem.img 注入 mbn | ❌ 失败 | Pixel 2 的 modem 不从 modem.img 读运营商配置 |
| crDroid ROM 的 mbn + .replace 替换 | ✅ 成功 | 正确来源 + 正确安装方式 |

---

## 常见问题 | FAQ

### Q: 安装后移动/联通卡还能用吗？
A: 能，而且比之前更好。之前没有中国运营商 mbn，移动联通靠 2G/3G 回落上网。现在有了完整配置，可以启用 VoLTE 高清通话。

### Q: Will China Mobile / China Unicom still work?
A: Yes, even better than before. The module adds proper mbn configs for all three Chinese carriers.

### Q: 会不会变砖？
A: 不会。模块只替换运营商配置文件，不修改 modem 固件。最坏情况是不生效，通过 Magisk 删除模块重启即可恢复。

### Q: Can this brick my phone?
A: No. The module only replaces carrier config files, not modem firmware. Worst case: it doesn't work. Remove the module via Magisk and reboot to restore.

### Q: 系统更新后需要重新安装吗？
A: 可能需要。OTA 更新可能会覆盖 vendor 分区，更新后检查一下网络是否正常，不正常就重新安装模块。

### Q: Do I need to reinstall after OTA updates?
A: Possibly. OTA updates may overwrite the vendor partition. Check network status after updates and reinstall if needed.

---

## 致谢 | Credits

- **[stanislawrogasik/Pixel2XL-VoLTE-VoWiFi](https://github.com/stanislawrogasik/Pixel2XL-VoLTE-VoWiFi)** — 原始 Magisk 模块作者
- **IonutGherman @ XDA** — 从 crDroid ROM 提取 mbn 文件
- **crDroid ROM** — mbn 文件来源
- **somin.n @ XDA** — [VoLTE 启用教程](https://xdaforums.com/t/guide-enable-volte-for-unsupported-carriers.3892659/)

---

## 关键词 | Keywords

Pixel 2, Pixel 2 XL, walleye, taimen, 中国电信, China Telecom, CT, 电信卡无法上网, 无服务, No Service, Emergency Calls Only, 仅限紧急呼叫, VoLTE, 4G LTE, mbn, mcfg_sw, Magisk, 骁龙835, Snapdragon 835, MSM8998, 运营商配置, carrier config, modem config, 中国移动, China Mobile, CMCC, 中国联通, China Unicom, CU, Google Pixel 中国使用, Pixel China fix, Pixel 电信修复
