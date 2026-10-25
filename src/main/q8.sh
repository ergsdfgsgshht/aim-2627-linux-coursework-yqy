#!/bin/bash
# Q8：repair 时识别并停止采集器、修复 HTTP 服务；cleanup 时停止修复后的服务。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

action=${3:-repair}

. "$input/process.env"
state=$output/.service

gone() {
    if ! kill -0 "$1" 2>/dev/null; then return 0; fi
    if [ "$(ps -o stat= -p "$1" 2>/dev/null | tr -d ' ')" = "Z" ]; then return 0; fi
    return 1
}

wait_exit() {
    local i
    for ((i = 0; i < 50; i++)); do
        if gone "$1"; then return 0; fi
        sleep 0.1
    done
}

if [ "$action" = "repair" ]; then
    read -r w_user w_state w_command <<< "$(ps -o user:32=,stat=,command= -p "$TARGET_PID")"
    {
        printf 'pid=%s\n' "$TARGET_PID"
        printf 'user=%s\n' "$w_user"
        printf 'state=%s\n' "$w_state"
        printf 'command=%s\n' "$w_command"
    } > "$output/process.txt"

    kill "$TARGET_PID" 2>/dev/null || true
    for ((i = 0; i < 40; i++)); do
        if grep -q "^STOP $TARGET_TOKEN\$" "$WORKER_LOG"; then break; fi
        sleep 0.1
    done
    cp "$WORKER_LOG" "$output/collector-sample.log"

    kill "$SERVICE_PID" 2>/dev/null || true
    wait_exit "$SERVICE_PID"

    printf 'bind=127.0.0.1\nport=%s\nroute=/status\n' "$TARGET_PORT" > "$output/server.conf"
    bash "$START_TOOL" "$output/server.conf" "$state"
    for ((i = 0; i < 50; i++)); do
        if curl -s -f -o /dev/null "http://127.0.0.1:$TARGET_PORT/status"; then break; fi
        sleep 0.1
    done
    curl -s -o "$output/http-body.txt" -w '%{http_code}\n' "http://127.0.0.1:$TARGET_PORT/status" > "$output/http-status.txt"
elif [ "$action" = "cleanup" ]; then
    if [ -f "$state/pid" ]; then
        spid=$(cat "$state/pid")
        kill "$spid" 2>/dev/null || true
        wait_exit "$spid"
    fi
fi
