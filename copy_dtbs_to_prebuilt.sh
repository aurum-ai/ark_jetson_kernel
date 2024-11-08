#!/bin/bash
DTBS_SOURCE_PATH="$ARK_JETSON_KERNEL_DIR/source_build/Linux_for_Tegra/source/nvidia-oot/device-tree/platform/generic-dts/dtbs"
PREBUILT_PATH="$ARK_JETSON_KERNEL_DIR/prebuilt/Linux_for_Tegra"
ARK_COMPILED_DEVICE_TREE_PATH="$ARK_JETSON_KERNEL_DIR/prebuilt/ark_jetson_compiled_device_tree_files/Linux_for_Tegra"

echo "Installing DTBs into prebuilt directory"
# Copy kernel device tree to bootloader path
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-nv.dtb $PREBUILT_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0001-nv.dtb $PREBUILT_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0003-nv.dtb $PREBUILT_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0004-nv.dtb $PREBUILT_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-dynamic.dtbo $PREBUILT_PATH/rootfs/boot/

# Copy kernel device tree to kernel path
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-nv.dtb $PREBUILT_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0001-nv.dtb $PREBUILT_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0003-nv.dtb $PREBUILT_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0004-nv.dtb $PREBUILT_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-dynamic.dtbo $PREBUILT_PATH/kernel/dtb/

# Copy camera overlays to kernel and bootloader paths
# IMX477 Single
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-p3768-ark-imx477-single.dtbo $PREBUILT_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-p3768-ark-imx477-single.dtbo $PREBUILT_PATH/kernel/dtb/
# IMX219 Quad
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-p3768-ark-imx219-quad.dtbo $PREBUILT_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-p3768-ark-imx219-quad.dtbo $PREBUILT_PATH/kernel/dtb/

# TC358743 HDMI-CSI
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-tc358743.dtbo $PREBUILT_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-tc358743.dtbo $PREBUILT_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-tc358743.dtb $PREBUILT_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-tc358743.dtb $PREBUILT_PATH/kernel/dtb/

echo "Removing non-supported overlays from prebuilt directory"
# Remove the overlays that don't work with ARK Carrier
file_names=(
	"tegra234-p3767-camera-p3768-imx219-A.dtbo"
	"tegra234-p3767-camera-p3768-imx219-ark-quad.dtbo"
	"tegra234-p3767-camera-p3768-imx219-C.dtbo"
	"tegra234-p3767-camera-p3768-imx219-dual.dtbo"
	"tegra234-p3767-camera-p3768-imx219-imx477.dtbo"
	"tegra234-p3767-camera-p3768-imx477-A.dtbo"
	"tegra234-p3767-camera-p3768-imx477-C.dtbo"
	"tegra234-p3767-camera-p3768-imx477-dual-4lane.dtbo"
	"tegra234-p3767-camera-p3768-imx477-dual.dtbo"
	"tegra234-p3767-camera-p3768-imx477-imx219.dtbo"
	"tegra234-p3767-camera-p3768-ov5647-single.dtbo"
)

for file in "${file_names[@]}"
do
    filepath="$ARK_JETSON_KERNEL_DIR/prebuilt/Linux_for_Tegra/rootfs/boot/$file"
    if [ -e "$filepath" ]; then
        echo "Removing $file..."
        sudo rm $filepath
    fi

    filepath="$ARK_JETSON_KERNEL_DIR/prebuilt/Linux_for_Tegra/kernel/dtb/$file"
    if [ -e "$filepath" ]; then
        echo "Removing $file..."
        sudo rm $filepath
    fi
done

echo "Installing DTBs into ark_jetson_compiled_device_tree_files directory"
# Copy kernel device tree to bootloader path
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-nv.dtb $ARK_COMPILED_DEVICE_TREE_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0001-nv.dtb $ARK_COMPILED_DEVICE_TREE_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0003-nv.dtb $ARK_COMPILED_DEVICE_TREE_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0004-nv.dtb $ARK_COMPILED_DEVICE_TREE_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-dynamic.dtbo $ARK_COMPILED_DEVICE_TREE_PATH/rootfs/boot/

# Copy kernel device tree to kernel path
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-nv.dtb $ARK_COMPILED_DEVICE_TREE_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0001-nv.dtb $ARK_COMPILED_DEVICE_TREE_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0003-nv.dtb $ARK_COMPILED_DEVICE_TREE_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0004-nv.dtb $ARK_COMPILED_DEVICE_TREE_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-dynamic.dtbo $ARK_COMPILED_DEVICE_TREE_PATH/kernel/dtb/

# Copy camera overlays to kernel and bootloader paths
# IMX477 Single
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-p3768-ark-imx477-single.dtbo $ARK_COMPILED_DEVICE_TREE_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-p3768-ark-imx477-single.dtbo $ARK_COMPILED_DEVICE_TREE_PATH/kernel/dtb/
# IMX219 Quad
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-p3768-ark-imx219-quad.dtbo $ARK_COMPILED_DEVICE_TREE_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-p3768-ark-imx219-quad.dtbo $ARK_COMPILED_DEVICE_TREE_PATH/kernel/dtb/
# TC358743 HDMI-CSI
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-tc358743.dtbo $ARK_COMPILED_DEVICE_TREE_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3767-camera-tc358743.dtbo $ARK_COMPILED_DEVICE_TREE_PATH/kernel/dtb/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-tc358743.dtb $ARK_COMPILED_DEVICE_TREE_PATH/rootfs/boot/
sudo cp $DTBS_SOURCE_PATH/tegra234-p3768-0000+p3767-0000-tc358743.dtb $ARK_COMPILED_DEVICE_TREE_PATH/kernel/dtb/
