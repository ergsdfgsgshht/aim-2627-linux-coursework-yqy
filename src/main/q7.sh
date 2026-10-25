#!/bin/bash
# Q7：读取 input/remote.env，生成 ssh_config，用 SSH 和 SCP 获取远程数据。
# 完整接口与验收规格见 Problem.pdf。只修改本文件，不修改测试或工具。
set -eu
input=${1:?需要输入目录}
output=${2:?需要输出目录}

. "$input/remote.env"
cfg=$output/ssh_config
{
    printf 'Host aim-sentry\n'
    printf '    HostName %s\n' "$HOST"
    printf '    Port %s\n' "$PORT"
    printf '    User %s\n' "$REMOTE_USER"
    printf '    IdentityFile "%s"\n' "$KEY_PATH"
    printf '    IdentitiesOnly yes\n'
    printf '    UserKnownHostsFile "%s"\n' "$KNOWN_HOSTS"
    printf '    StrictHostKeyChecking yes\n'
} > "$cfg"
chmod 600 "$cfg"

ssh -F "$cfg" -o BatchMode=yes aim-sentry whoami > "$output/remote-user.txt"

# 远程私有日志路径含空格，先复制到远端主目录的中转名，再用 scp 取回。
mkdir -p "$output/received"
relay="aim-relay-$$.log"
printf -v fetch 'cat %q > %q' "$REMOTE_LOG" "$relay"
ssh -F "$cfg" -o BatchMode=yes aim-sentry "$fetch"
scp -F "$cfg" -o BatchMode=yes "aim-sentry:$relay" "$output/received/errors.log"
printf -v clean 'rm -f %q' "$relay"
ssh -F "$cfg" -o BatchMode=yes aim-sentry "$clean"
