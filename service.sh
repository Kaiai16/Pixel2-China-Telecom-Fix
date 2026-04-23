#!/system/bin/sh
# Pixel 2 中国电信修复 — service 阶段
# 清理 modem 缓存 + 飞行模式恢复网络
MODDIR=${0%/*}

sleep 10

# 清除残留 persist 属性
resetprop -p persist.dbg.ims_volte_enable 0
resetprop -p persist.data.iwlan.enable false
resetprop -p persist.data.iwlan 0
resetprop -p persist.data.iwlan.ipsec.ap 0

# 清除 modem FDR 缓存
rm -rf /data/vendor/modem_fdr/*

# 飞行模式切换恢复网络
sleep 3
cmd connectivity airplane-mode enable
sleep 3
cmd connectivity airplane-mode disable
