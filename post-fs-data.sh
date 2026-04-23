#!/system/bin/sh
# Pixel 2 中国电信修复 — post-fs-data 阶段
# 禁用 VoLTE/IMS 防止不必要的 IMS 注册
MODDIR=${0%/*}

resetprop persist.dbg.volte_avail_ovr 0
resetprop persist.dbg.ims_volte_enable 0
resetprop persist.dbg.wfc_avail_ovr 0
resetprop persist.dbg.vt_avail_ovr 0
resetprop persist.vendor.radio.calls.on.ims 0
resetprop persist.radio.calls.on.ims 0
resetprop persist.data.iwlan 0
resetprop persist.data.iwlan.enable false
