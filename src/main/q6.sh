#!/bin/bash
# Q6：将本地 Debian 包安装到 output/sysroot，运行安装后的工具。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

root=$output/sysroot
admin=$root/var/lib/dpkg
# dpkg 启动检查需要 ldconfig/start-stop-daemon（位于 sbin 目录）
PATH=$PATH:/usr/sbin:/sbin
mkdir -p "$admin/updates" "$admin/info"
: > "$admin/status"
dpkg --admindir="$admin" --instdir="$root" --log=/dev/null --force-not-root -i "$input/aim-sentry-tools.deb"
"$root/usr/bin/aim-sentry-info" > "$output/tool-output.txt"
