# Base image
FROM ubuntu:22.04

# Non-interactive install
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles

# Update + install base dependencies
RUN apt-get update && apt-get install -y \
    tzdata \
    vim git make sed binutils diffutils python3 ninja-build build-essential \
    curl bzip2 tar findutils unzip cmake \
    rsync libglib2.0-dev libpixman-1-dev wget cpio bc \
    libncurses5 libncurses5-dev flex bison openssl libssl-dev kmod \
    python3-pip file pkg-config u-boot-tools \
    && rm -rf /var/lib/apt/lists/*

# Python deps
RUN pip3 install --no-cache-dir Mako

# Native cross-compilers from Ubuntu repos
RUN apt-get update && apt-get install -y \
    gcc-arm-none-eabi \
    gcc-aarch64-linux-gnu \
    && rm -rf /var/lib/apt/lists/*

# Install aarch64-none-elf cross-compiler
RUN curl -fLo /tmp/gcc-aarch64-none-eabi.tar.xz \
      --retry 5 --retry-delay 5 --retry-connrefused \
      "https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-elf.tar.xz" \
    && mkdir -p /opt/gcc-aarch64-none-eabi \
    && tar xf /tmp/gcc-aarch64-none-eabi.tar.xz --strip-components=1 -C /opt/gcc-aarch64-none-eabi \
    && rm /tmp/gcc-aarch64-none-eabi.tar.xz
ENV PATH="/opt/gcc-aarch64-none-eabi/bin:${PATH}"

# Install riscv32-elf cross-compiler
RUN curl -fLo /tmp/rv32.tar.xz \
      --retry 5 --retry-delay 5 --retry-connrefused \
      "https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2025.01.20/riscv32-elf-ubuntu-22.04-gcc-nightly-2025.01.20-nightly.tar.xz" \
    && mkdir -p /opt/rv32 \
    && tar xf /tmp/rv32.tar.xz --strip-components=1 -C /opt/rv32 \
    && rm /tmp/rv32.tar.xz
ENV PATH="/opt/rv32/bin:${PATH}"

# Terminal settings + colorful prompt and aliases (for all users)
ENV TERM=xterm-256color
RUN echo "PS1='\[\e[1;32m\]\u\[\e[0m\]@\[\e[1;33m\]\h \[\e[1;36m\]\w \[\e[38;5;46;1m\]➜\[\e[0m\] '" >> /etc/bash.bashrc && \
    echo "alias ls='ls --color=auto'" >> /etc/bash.bashrc && \
    echo "alias grep='grep --color=auto'" >> /etc/bash.bashrc && \
    echo "alias ll='ls -alF'" >> /etc/bash.bashrc && \
    echo "alias la='ls -A'" >> /etc/bash.bashrc && \
    echo "alias l='ls -CF'" >> /etc/bash.bashrc

# Default working directory
WORKDIR /home
ENV HOME=/home

# Default entrypoint: interactive login shell
CMD ["bash", "-il"]
