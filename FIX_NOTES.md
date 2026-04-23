# Modem SSR 修复记录

## 问题
安装 Pixel2VolteVoWiFi 模块后，modem 每隔 ~13 秒 Root PD crash 导致 SSR 循环，蜂窝网络反复断连。

## 根因
原始模块在 `mcfg_sw/` 目录放置 `.replace` 文件，Magisk 会完全替换原始 vendor 的 MBN 目录。
替换后的 167 个 crDroid MBN 文件中有部分与 Pixel 2 MSM8998 modem 固件不兼容，导致 modem 内部崩溃。

## 排查过程
1. 精简到只保留 4 个中国电信 MBN → 仍然 SSR（排除数量问题）
2. 禁用整个模块 → modem 稳定但无法注册电信网络（确认是 MBN 导致）
3. 只保留 1 个 openmkt MBN + .replace → modem 稳定但无法注册（原始 MBN 被替换掉了）
4. 删除 .replace 改为 overlay 模式 → 原始 MBN 保留 + CT MBN 叠加 → 成功

## 修复方案
1. 删除 `system/vendor/mbn/mcfg/configs/mcfg_sw/.replace`
2. 只保留 `china/ct/commerci/openmkt/mcfg_sw.mbn` 一个中国电信 MBN
3. 更新 `oem_sw.txt` 只列出实际存在的 27 个 MBN（26 原始 + 1 CT）
4. 精简 `system.prop` 去掉 VoLTE/IMS/iwlan 属性
5. 去掉 `system/vendor/bin/` 下的 IMS 二进制 toybox 替换

## 测试结果
重启后连续 90 秒 LTE + CHN-CT，0 次 modem SSR。
