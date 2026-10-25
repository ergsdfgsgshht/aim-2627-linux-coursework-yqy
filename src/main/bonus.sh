#!/bin/bash
# Bonus：start 时创建分离的 tmux 会话和采集器；stop 时正常停止采集器并结束会话。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-start}

. "$input/bonus.env"
log=$output/bonus.log

if [ "$action" = "start" ]; then
    printf -v cmd 'python3 %q --token %q --log %q' "$WORKER_TOOL" "$TOKEN" "$log"
    tmux -L "$TMUX_SOCKET" new-session -d -s "$SESSION" "$cmd"
else
    if [ -f "$log" ]; then
        pid=$(sed -n "s/^START $TOKEN pid=//p" "$log" | tail -n 1)
        if [ -n "$pid" ]; then
            kill "$pid" 2>/dev/null || true
            for ((i = 0; i < 40; i++)); do
                if grep -q "^STOP $TOKEN\$" "$log"; then break; fi
                sleep 0.1
            done
        fi
    fi
    tmux -L "$TMUX_SOCKET" kill-session -t "$SESSION" 2>/dev/null || true
fi
