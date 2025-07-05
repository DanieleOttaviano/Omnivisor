FROM ubuntu:22.04

RUN apt-get update

ENV TZ=America/Los_Angeles

RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt-get install -y vim git make sed binutils diffutils python3 ninja-build build-essential curl bzip2 tar findutils unzip cmake

RUN apt-get install -y rsync libglib2.0-dev libpixman-1-dev wget cpio rsync bc libncurses5 libncurses5-dev flex bison openssl libssl-dev kmod python3-pip file pkg-config rsync u-boot-tools 

RUN pip3 install Mako

# Install arch32 and aarch64-linux cross-compilers (Ubuntu Native)
RUN apt-get install -y gcc-arm-none-eabi gcc-aarch64-linux-gnu
 
# Download and install the aarch64-none-elf cross-compiler
RUN curl -fLo gcc-aarch64-none-eabi.tar.xz \
    --retry 5 \
    --retry-delay 5 \
    --retry-connrefused \
    "https://developer.arm.com/-/media/Files/downloads/gnu/12.2.rel1/binrel/arm-gnu-toolchain-12.2.rel1-x86_64-aarch64-none-elf.tar.xz"
RUN mkdir -p /opt/gcc-aarch64-none-eabi
RUN tar xf gcc-aarch64-none-eabi.tar.xz --strip-components=1 -C /opt/gcc-aarch64-none-eabi
ENV PATH="/opt/gcc-aarch64-none-eabi/bin:${PATH}"

# Download and install the riscv32-unknown-elf- cross-compiler
RUN curl -fLo rv32.tar.xz \
    --retry 5 \
    --retry-delay 5 \
    --retry-connrefused \
    "https://github.com/riscv-collab/riscv-gnu-toolchain/releases/download/2025.01.20/riscv32-elf-ubuntu-22.04-gcc-nightly-2025.01.20-nightly.tar.xz"
RUN mkdir -p /opt/rv32
RUN tar xf rv32.tar.xz --strip-components=1 -C /opt/rv32
ENV PATH="/opt/rv32/bin:${PATH}" 


ENV TERM=xterm-256color

RUN echo "PS1='\[\e[38;5;39m\]\w\[\e[0m\] \[\e[38;5;46;1m\]>\[\e[0m\] '" >> /root/.bashrc

RUN echo "source /root/.bashrc" >> /root/.profile

ENV HOME=/home
#RUN source /root/.bashrc
# Set the entry point to source .bashrc and start bash

CMD ["bash", "-c", "source /root/.bashrc && exec /bin/bash -il"]

#RUN source /root/.bashrc
