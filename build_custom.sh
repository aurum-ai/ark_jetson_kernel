#!/bin/bash
export ARK_JETSON_KERNEL_DIR=/code/third-party/ark_jetson_kernel
export CROSS_COMPILE=$HOME/l4t-gcc/aarch64--glibc--stable-2022.08-1/bin/aarch64-buildroot-linux-gnu-
export KERNEL_HEADERS=$ARK_JETSON_KERNEL_DIR/source_build/Linux_for_Tegra/source/kernel/kernel-jammy-src
cd $ARK_JETSON_KERNEL_DIR
echo "Copying build files"
cp -r source_build/ark_jetson_orin_nano_nx_device_tree/* source_build/Linux_for_Tegra/source/hardware/nvidia/t23x/nv-public/
cd $ARK_JETSON_KERNEL_DIR/source_build/Linux_for_Tegra/source/

echo "Making dtbs"
make dtbs

echo "starting scp"
scp ./out/nvidia-linux-header/drivers/media/i2c/tc358743.ko jetson@192.168.1.25:~/
scp ./nvidia-oot/device-tree/platform/generic-dts/dtbs/tegra234-p3767-camera-tc358743.dtbo jetson@192.168.1.25:~/
scp ./nvidia-oot/device-tree/platform/generic-dts/dtbs/tegra234-p3768-0000+p3767-0000-tc358743.dtb jetson@192.168.1.25:~/
echo "done!"
