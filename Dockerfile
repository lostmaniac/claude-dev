FROM ubuntu:24.04

# 设置非交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 安装基础依赖、SSH和常用开发工具
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    nano \
    vim \
    tmux \
    htop \
    tree \
    iputils-ping \
    netcat-openbsd \
    telnet \
    dnsutils \
    iproute2 \
    iptables \
    sudo \
    psmisc \
    procps \
    lsof \
    strace \
    jq \
    ca-certificates \
    openssh-server \
    openssh-client \
    build-essential \
    git \
    rsync \
    zip \
    unzip \
    fish \
    zsh \
    fzf \
    ripgrep \
    bat \
    eza \
    && rm -rf /var/lib/apt/lists/*

# 配置SSH - 只允许密钥登录，禁用密码，启用SFTP
RUN mkdir /var/run/sshd && \
    sed -i 's/#*PermitRootLogin.*/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config && \
    sed -i 's/#*PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed -i 's/#*PubkeyAuthentication.*/PubkeyAuthentication yes/' /etc/ssh/sshd_config && \
    sed -i 's/#*UsePAM.*/UsePAM no/' /etc/ssh/sshd_config && \
    sed -i 's/^Subsystem sftp.*/Subsystem sftp internal-sftp/' /etc/ssh/sshd_config

# 创建SSH目录和authorized_keys文件（为空，用户需要手动添加公钥）
RUN mkdir -p /root/.ssh && touch /root/.ssh/authorized_keys && chmod 700 /root/.ssh && chmod 600 /root/.ssh/authorized_keys

# 安装uv
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

# 安装nvm
ENV NVM_DIR="/root/.nvm"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash

# 加载nvm并安装最新Node.js
RUN bash -c 'source $NVM_DIR/nvm.sh && nvm install node && nvm use node && nvm alias default node'

# 设置Node.js环境变量
ENV NODE_PATH="/root/.nvm/versions/node/$(bash -c 'source $NVM_DIR/nvm.sh && nvm current')/lib/node_modules"
ENV PATH="/root/.nvm/versions/node/$(bash -c 'source $NVM_DIR/nvm.sh && nvm current')/bin:$PATH"

# 安装Claude Code
RUN curl -fsSL https://claude.ai/install.sh | bash
ENV PATH="/root/.local/bin:$PATH"

# 设置 apt 国内源（清华源）- Ubuntu 24.04 使用 DEB822 格式
RUN sed -i 's|URIs: http://archive.ubuntu.com/ubuntu|URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu|g' /etc/apt/sources.list.d/ubuntu.sources && \
    sed -i 's|URIs: http://security.ubuntu.com/ubuntu|URIs: https://mirrors.tuna.tsinghua.edu.cn/ubuntu|g' /etc/apt/sources.list.d/ubuntu.sources

# 设置 npm 国内源（淘宝镜像）
RUN npm config set registry https://registry.npmmirror.com

# 设置 pip 国内源（清华源）
RUN mkdir -p ~/.pip && \
    echo '[global]' > ~/.pip/pip.conf && \
    echo 'index-url = https://pypi.tuna.tsinghua.edu.cn/simple' >> ~/.pip/pip.conf && \
    echo 'trusted-host = pypi.tuna.tsinghua.edu.cn' >> ~/.pip/pip.conf

# 创建root目录备份，用于首次挂载时初始化
RUN mkdir -p /root.original && \
    cp -a /root/. /root.original/ && \
    rm -rf /root/.ssh/authorized_keys

# 暴露SSH端口
EXPOSE 22

# 复制启动脚本
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 启动SSH服务
CMD ["/usr/local/bin/entrypoint.sh"]
