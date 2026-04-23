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

## ⚠️ 安装后必做：替换 system.prop

原始模块的 `system.prop` 包含大量不适合 Pixel 2 的属性（来自努比亚等其他机型），会导致 **WiFi 和蜂窝信号每隔几秒断连一次**。安装模块后必须用下面的干净版本完全替换。

### 问题根因

原始 `system.prop` 中有两类有害属性：

**第一类：iWLAN / WiFi Calling 属性**（Pixel 2 电信卡不支持 WiFi Calling）
- `persist.dbg.ims_volte_enable=1`
- `persist.data.iwlan.enable=true`
- `persist.data.iwlan=1`
- `persist.data.iwlan.ipsec.ap=1`

**第二类：VT / WFC / 5G / IMS 属性**（来自其他机型，Pixel 2 不支持）
- `persist.dbg.wfc_avail_ovr=1` — 强制开启 WiFi Calling
- `persist.dbg.vt_avail_ovr=1` — 强制开启视频通话
- `persist.radio.VT_HYBRID_ENABLE=1` — 混合视频通话
- `persist.radio.calls.on.ims=1` — 强制 IMS 通话
- `persist.vendor.radio.calls.on.ims=1` — 强制 IMS 通话（vendor 层）
- `persist.nubia.5g.power.config=1` — 努比亚 5G 配置
- `ro.nubia.nr.support=1` — 努比亚 5G 支持
- `ro.vendor.radio.5g=3` — 5G 射频配置

这些属性会导致 `vendor.imsrcsservice` 进入崩溃循环（可通过 `getprop sys.init.updatable_crashing_process_name` 确认），IMS 服务反复崩溃重启会拖垮整个网络栈，WiFi 和蜂窝都跟着断。

### 修复方法：一键替换为干净的 system.prop

```bash
# 用干净版本完全替换 system.prop
adb shell "su -c 'cat > /data/adb/modules/Pixel2VolteVoWiFi/system.prop << EOF
persist.radio.rat_on=combine
persist.rcs.supported=0
persist.radio.data_ltd_sys_ind=1
persist.radio.data_con_rprt=1
persist.vendor.radio.force_ltd_sys_ind=1
persist.vendor.radio.data_ltd_sys_ind=1
persist.vendor.radio.enable_temp_dds=true
persist.vendor.radio.redir_party_num=1
persist.vendor.radio.force_on_dc=true
persist.sys.strictmode.disable=true
persist.radio.dynamic_sar=false
persist.vendor.radio.data_con_rprt=1
persist.vendor.dpm.feature=1
ro.telephony.default_cdma_sub=0
ril.subscription.types=RUIM
persist.radio.force_on_dc=true
persist.radio.NO_STAPA=1
persist.dbg.volte_avail_ovr=1
EOF'"

# 删除残留的 persist 属性文件
adb shell "su -c 'rm -f /data/property/persistent_properties'"

# 清除 modem 缓存
adb shell "su -c 'rm -rf /data/vendor/radio/* /data/vendor/modem_fdr/*'"

# 重启
adb reboot
```

**为什么要完全替换而不是只删几行？** 原始文件中有害属性太多且分散，逐行删除容易遗漏。直接用验证过的干净版本替换最安全。

**为什么只删 `persistent_properties` 不够？** 因为 Magisk 每次开机都会从模块的 `system.prop` 重新注入这些属性，所以必须从源头（`system.prop` 文件）修改，否则重启后问题会复发。

## ⚠️ 其他注意事项

**禁止手动设置 VoLTE 相关的 persist 属性！** 模块的 `system.prop` 已经包含了所有必要的属性配置。如果你手动执行了类似以下命令：

```bash
# ❌ 不要这样做
setprop persist.dbg.ims_volte_enable 1
setprop persist.radio.rat_on combine
setprop persist.data.iwlan.enable true
setprop persist.dbg.wfc_avail_ovr 1
setprop persist.dbg.vt_avail_ovr 1
```

这些手动设置的 persist 属性会与模块冲突，导致 **WiFi 和蜂窝信号反复断连**。

如果已经误操作，修复方法同上：替换 `system.prop` + 删除 `persistent_properties` + 清除 modem 缓存 + 重启。

## 验证

```bash
# 应显示 LTE
adb shell "getprop gsm.network.type"

# 应显示 CHN-CT
adb shell "getprop gsm.operator.alpha"

# 以下属性应为空（无输出）
adb shell "getprop persist.dbg.ims_volte_enable"
adb shell "getprop persist.data.iwlan"
adb shell "getprop persist.dbg.wfc_avail_ovr"
adb shell "getprop persist.dbg.vt_avail_ovr"

# IMS 服务不应在崩溃（应为空）
adb shell "getprop sys.init.updatable_crashing_process_name"
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
这是模块 `system.prop` 中的冲突属性导致的，参考上方「安装后必做」章节替换为干净的 system.prop 即可。

**怎么判断是不是这个问题？**
执行 `adb shell "getprop sys.init.updatable_crashing_process_name"`，如果输出 `vendor.imsrcsservice`，说明 IMS 服务在崩溃循环，就是 system.prop 的问题。

## 致谢

- [stanislawrogasik/Pixel2XL-VoLTE-VoWiFi](https://github.com/stanislawrogasik/Pixel2XL-VoLTE-VoWiFi) — 原始 Magisk 模块作者
- IonutGherman @ XDA — 从 crDroid ROM 提取 mbn 文件
- [somin.n @ XDA](https://xdaforums.com/t/guide-enable-volte-for-unsupported-carriers.3892659/) — VoLTE 启用教程

## 许可证

[MIT](LICENSE)
