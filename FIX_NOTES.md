# Pixel 2 中国电信 Modem SSR 修复记录

## 设备信息
- Pixel 2 (walleye)，FA7AK1A00719，Android 11，Magisk 25.2
- 中国电信 SIM（IMSI 460/11）
- 原始模块：stanislawrogasik/Pixel2XL-VoLTE-VoWiFi（167 个 crDroid MBN）

## 问题
安装 Pixel2VolteVoWiFi 模块后，modem 每隔 ~13 秒 Root PD crash 导致 SSR 循环，蜂窝网络反复断连。dmesg 可见 `subsystem_restart_dev(): Restart sequence requested for modem`。

## 排查过程（2026-04-22 ~ 04-23）

### 第一轮：精简 MBN（无效）
1. 删除所有非 china 地区 MBN（APAC/EU/NA/AUS 等），只保留 china/ct 4 个 commercial MBN → 仍然 SSR（~13 秒循环）
2. 进一步只保留 openmkt 1 个 MBN → modem 稳定（0 次 SSR）但无法注册电信网络
3. 禁用整个模块（touch disable）→ modem 稳定但无法注册（确认是 MBN 导致 SSR）
4. **结论：SSR 不是 MBN 数量问题，而是 CT MBN 本身触发 IMS 注册导致 modem crash**

### 第二轮：overlay 模式（部分成功）
5. 删除 `.replace` 文件改为 Magisk overlay 叠加模式 → 原始 26 个 Pixel 2 MBN 保留 + CT openmkt 叠加
6. 更新 `oem_sw.txt` 只列出实际存在的 27 个 MBN
7. 首次测试：**90 秒连续 LTE + CHN-CT，0 次 SSR** ✅
8. 重启后复测：一直"正在搜索服务"，无法注册 ❌
9. **原因：首次成功是因为 modem 缓存（/data/vendor/radio/）里还有之前 .replace 模式下加载的 CT 配置。重启后 service.sh 清了 modem_fdr 缓存，modem 重新加载时 overlay 模式下的 CT MBN 没被正确选择**

### 第三轮：.replace + 原始 MBN 合并（无效）
10. 恢复 `.replace` 模式，通过 Magisk mirror 路径（`/dev/VRt/.magisk/mirror/vendor/`）复制 Pixel 2 原始 26 个 MBN 到模块目录 + CT MBN
11. 总共 30 个 MBN（26 原始 + 4 CT commercial）→ 一直"正在搜索服务"
12. **原因：service.sh 的 `rm -rf /data/vendor/modem_fdr/*` 清了缓存，modem 需要 FDR 数据来完成 MBN 自动选择**

### 第四轮：不清缓存（无效）
13. 改 service.sh 不清 modem_fdr → modem 稳定但不注册网络
14. 恢复全部 167 个 crDroid MBN + 不清缓存 → 同样不注册
15. **原因：之前多次清理 /data/vendor/radio/ 和 /data/vendor/modem_fdr/ 破坏了 modem 的 MBN 自动选择数据库**

### 第五轮：属性恢复（无效）
16. 发现 `persist.dbg.volte_avail_ovr` 和 `persist.dbg.ims_volte_enable` 实际值为 0（被之前的 resetprop -p 持久化），而 system.prop 写的是 1
17. 用 `resetprop -p` 恢复所有属性为原始模块的值（1）→ 仍然不注册

### 第六轮：完全重装（成功恢复 SSR 循环状态）
18. 完全删除模块 + 删除 /data/vendor/radio/ 和 /data/vendor/modem_fdr/
19. 无模块状态重启，让系统重建 radio 目录
20. 重新安装原始模块（`magisk --install-module`）
21. 重启后 → **LTE + CHN-CT 恢复，但 SSR 循环也回来了**（每 ~12 秒断连）
22. **结论：模块安装时的 customize.sh 会清缓存并触发 modem 重新加载 MBN，这是让 CT MBN 生效的关键步骤**

### 第七轮：安装后立即修改（当前状态）
23. 趁 modem 已加载 CT MBN 并建立缓存，立即：删除 `.replace` + 空 service.sh/post-fs-data.sh + 精简 system.prop
24. 重启后 → **LTE + CHN-CT 能连上，但 SSR 循环仍在**（每 ~12 秒断连 5-6 秒）
25. 尝试用原始 vendor 的 oem_sw.txt（不含 CT 路径）→ SSR 循环不变
26. **结论：SSR 的根因是 CT MBN 配置触发了 modem 内部的 IMS 注册流程，IMS 在 Pixel 2 MSM8998 modem 上不兼容导致 Root PD crash。不管 oem_sw.txt 怎么改、MBN 怎么精简，只要 modem 缓存里有 CT 配置就会 SSR**

## 已尝试但无效的方案汇总
| 方案 | 结果 |
|------|------|
| resetprop 禁用 VoLTE/IMS 属性（persist.dbg.volte_avail_ovr=0 等） | modem SSR 不受 Android 属性控制 |
| service.sh 循环 stop IMS 服务 | IMS 停了但 modem 仍 SSR |
| toybox 替换 IMS 二进制（imsqmidaemon 等） | 消除 updatable_crashing 标记但 modem 仍 SSR |
| 清理 modem_config + 飞行模式切换 | 能临时恢复但很快又断 |
| 精简 MBN 到只有 CT commercial（4 个） | 仍然 SSR |
| 精简 MBN 到只有 CT openmkt（1 个） | 不 SSR 但无法注册网络 |
| 删除 .replace 改 overlay 模式 | 首次靠缓存成功，重启后失效 |
| .replace + 原始 Pixel 2 MBN + CT MBN | 不注册网络 |
| 不清 modem_fdr 缓存 | 不注册网络 |
| 恢复所有属性为原始模块值 | 不注册网络 |
| 完全删除模块 + 重装 | 恢复到 SSR 循环状态 |

## 当前状态
- 模块已恢复安装，LTE + CHN-CT 可用但 SSR 循环（每 ~12 秒断连 5-6 秒，连接率约 50%）
- modem SSR 是 CT MBN 触发 IMS 注册 → modem 固件内部 Root PD crash 的固有问题
- Pixel 2 MSM8998 modem 固件不支持中国电信的 IMS 配置

## 可能的后续方向
- 从其他支持电信的 Pixel ROM（如 GrapheneOS、CalyxOS）提取 MBN，可能有更兼容的版本
- 换移动/联通 SIM 卡（这两家在 Pixel 2 上通常没有 SSR 问题）
- 恢复出厂设置后重新安装模块（可能恢复到"安装后能用"的状态）
- 研究 modem 固件层面禁用 IMS 的方法（需要 QPST/QXDM 工具）
