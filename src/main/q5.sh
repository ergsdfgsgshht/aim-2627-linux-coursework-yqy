#!/bin/bash
# Q5：运行 launch.env 给定的启动前检查，保存 stdout/stderr、真实退出码和诊断报告。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

. "$input/launch.env"
code=0
bash "$LAUNCH_TOOL" "$MODEL_PATH" "$CAMERA_PATH" > "$output/stdout.log" 2> "$output/stderr.log" || code=$?
printf '%s\n' "$code" > "$output/exit-code.txt"
if [ "$code" -eq 0 ]; then
    result=SUCCESS
    reason=NONE
elif grep -q 'MODEL_MISSING' "$output/stderr.log"; then
    result=FAILED
    reason=MODEL_MISSING
elif grep -q 'CAMERA_DENIED' "$output/stderr.log"; then
    result=FAILED
    reason=CAMERA_DENIED
else
    result=FAILED
    reason=UNKNOWN
fi
printf 'result=%s\nexit_code=%s\nreason=%s\n' "$result" "$code" "$reason" > "$output/report.txt"
