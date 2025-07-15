#!/bin/bash

set -e

echo "[+] Cloning ImmortalWrt-Nss repository..."
git clone https://github.com/NuhaHumaira/ImmortalWrt-Nss.git
cd ImmortalWrt-Nss

echo "[+] Updating system packages..."
sudo apt update
sudo apt install -y build-essential flex bison gawk gcc-multilib \
  git make ncurses-dev libncurses5-dev zlib1g-dev \
  g++ python3 unzip file wget rsync quilt

echo "[+] Updating and installing feeds..."
./scripts/feeds update -a
./scripts/feeds install -a

echo "[+] Launching menuconfig..."
make menuconfig

echo "[+] Running make defconfig..."
make defconfig

# echo "[+] Syncing kernel config..."
# make kernel_oldconfig

# echo "[+] Refreshing kernel patches..."
# make target/linux/refresh V=s

echo "[+] Starting parallel build..."
if ! make -j$(nproc); then
  echo "[!] Parallel build failed. Retrying with single thread and verbose output..."
  if ! make -j1 V=s; then
    echo "[!] Single-thread build failed. Attempting recovery for kernel-headers..."

    make toolchain/kernel-headers/clean
    if ! make toolchain/kernel-headers/compile V=s; then
      echo "[✘] kernel-headers still failed to compile. Exiting."
      exit 1
    fi

    echo "[+] Retrying full build after toolchain fix..."
    if ! make -j1 V=s; then
      echo "[✘] Final build still failed after toolchain fix. Exiting."
      exit 1
    fi
  fi
fi

echo "[✓] Build completed successfully."

echo "[+] Firmware files are located in ./bin/"
