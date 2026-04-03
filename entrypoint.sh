#!/bin/bash

# 检查 /root 目录是否为空或只包含挂载的目录
# 如果是，从备份目录复制所有文件
file_count=$(ls -la /root | wc -l)
if [ "$file_count" -le 3 ]; then
    echo "Initializing /root directory from backup..."
    cp -a /root.original/. /root/
    # 保持 authorized_keys 为空，由用户自行添加
    truncate -s 0 /root/.ssh/authorized_keys
fi

# 启动 SSH 服务
exec /usr/sbin/sshd -D
