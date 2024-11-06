# Notes to getting this working

## Kernel Modules

To get the kernel module for the TC358743 HDMI to CSI-2 bridge working, I had to add the following to setup.sh:

```bash
echo "CONFIG_MEDIA_CONTROLLER=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_VIDEO_V4L2_SUBDEV_API=y" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_HDMI=y" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_V4L2_FWNODE=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_VIDEO_TC358743=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_MEDIA_SUPPORT=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_MEDIA_CONTROLLER_REQUEST_API=y" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_MEDIA_CEC_SUPPORT=y" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_CEC_CORE=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_VIDEO_V4L2=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_VIDEO_DEV=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_VIDEOBUF2_CORE=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_VIDEOBUF2_V4L2=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_VIDEOBUF2_MEMOPS=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
echo "CONFIG_VIDEOBUF2_VMALLOC=m" >> kernel/kernel-jammy-src/arch/arm64/configs/defconfig
```

building:
```bash
export CROSS_COMPILE=$HOME/l4t-gcc/aarch64--glibc--stable-2022.08-1/bin/aarch64-buildroot-linux-gnu-
export KERNEL_HEADERS=$ARK_JETSON_KERNEL_DIR/source_build/Linux_for_Tegra/source/kernel/kernel-jammy-src
export INSTALL_MOD_PATH=$ARK_JETSON_KERNEL_DIR/prebuilt/Linux_for_Tegra/rootfs/
cd $ARK_JETSON_KERNEL_DIR/source_build/Linux_for_Tegra/source
tail kernel/kernel-jammy-src/arch/arm64/configs/defconfig
make modules
scp ./out/nvidia-linux-header/drivers/media/i2c/tc358743.ko jetson@aurum-dev-af-1:/home/jetson/
```

But it still gives the error: `[  362.056242] tc358743: no symbol version for module_layout`

## Camera blacklist
```bash
cat /etc/modprobe.d/blacklist-cameras.conf
blacklist nv_imx219
blacklist tegra_camera
blacklist tegra_camera_platform
blacklist tegra_camera_rtcpu
blacklist nvhost_nvcsi
blacklist nvhost_vi5
blacklist nvhost_isp5
blacklist nvhost_nvcsi_t194
```

## Device Tree

To get the device tree overlay for the TC358743 HDMI to CSI-2 bridge working, in setup.sh the ark_jetson_orin_nano_nx_device_tree repo is copied to the source:
```
cp -r ark_jetson_orin_nano_nx_device_tree/* Linux_for_Tegra/source/hardware/nvidia/t23x/nv-public/
```

On the host:
```bash
export ARK_JETSON_KERNEL_DIR=/code/third-party/ark_jetson_kernel
export CROSS_COMPILE=$HOME/l4t-gcc/aarch64--glibc--stable-2022.08-1/bin/aarch64-buildroot-linux-gnu-
export KERNEL_HEADERS=$ARK_JETSON_KERNEL_DIR/source_build/Linux_for_Tegra/source/kernel/kernel-jammy-src
cd $ARK_JETSON_KERNEL_DIR
cp -r source_build/ark_jetson_orin_nano_nx_device_tree/* source_build/Linux_for_Tegra/source/hardware/nvidia/t23x/nv-public/
cd $ARK_JETSON_KERNEL_DIR/source_build/Linux_for_Tegra/source/
make dtbs
scp ./out/nvidia-linux-header/drivers/media/i2c/tc358743.ko jetson@192.168.1.25:~/
scp ./nvidia-oot/device-tree/platform/generic-dts/dtbs/tegra234-p3767-camera-tc358743.dtbo jetson@192.168.1.25:~/
scp ./nvidia-oot/device-tree/platform/generic-dts/dtbs/tegra234-p3768-0000+p3767-0000-tc358743.dtb jetson@192.168.1.25:~/
```

On the device:
```bash
sudo cp -f tegra234-p3767-camera-tc358743.dtbo /boot/
sudo cp -f tegra234-p3768-0000+p3767-0000-tc358743.dtb /boot/kernel_tegra234-p3768-0000+p3767-0000-tc358743.dtb
sudo cp -f tegra234-p3768-0000+p3767-0000-tc358743.dtb /boot/dtb/kernel_tegra234-p3768-0000+p3767-0000-tc358743.dtb

cat /boot/extlinux/extlinux.conf # check that the we're using our custom dtb and also the overlay
sudo reboot
sudo insmod tc358743.ko
```

To get it to load cleanly:
```bash
sudo rmmod videobuf2_dma_contig
sudo rmmod videobuf2_memops
sudo rmmod videobuf2_common
sudo rmmod videodev
sudo modprobe mc
sudo insmod videodev.ko 
sudo insmod v4l2-async.ko 
sudo insmod v4l2-dv-timings.ko 
sudo insmod v4l2-fwnode.ko 
sudo insmod videobuf2-common.ko 
sudo insmod videobuf2-v4l2.ko 
sudo insmod videobuf2-memops.ko 
sudo insmod videobuf2-vmalloc.ko 
sudo insmod cec.ko
sudo insmod tc358743.ko 
```

## Checklist
- [ ] Verify i2c-2 exists and is enabled
    ```bash
    ls -l /sys/bus/i2c/devices/ | grep i2c-2
    ```
- [ ] Verify TCA9546 mux is present at 0x70 on i2c-2
    ```bash
    sudo i2cdetect -y -r 2  # Should show 0x70
    ```
- [ ] Verify muxed buses (i2c-3 through i2c-6) are created
    ```bash
    ls -l /sys/bus/i2c/devices/ | grep "i2c-[3-6]"
    ```
- [ ] Verify IMX modules are not loading
    ```bash
    lsmod | grep imx
    lsmod | grep tegra_camera
    ```
- [ ] Verify blacklist is in place
    ```bash
    cat /etc/modprobe.d/blacklist-cameras.conf
    ```
- [ ] Verify base DTB is loaded
    ```bash
    cat /proc/device-tree/compatible
    ```
- [ ] Verify overlay is applied
    ```bash
    ls -l /proc/device-tree/chosen/overlays/
    ```
- [ ] Verify TC358743 node exists
    ```bash
    find /proc/device-tree -name "*tc358743*"
    ```
- [ ] Verify TC358743 is present on mux channel 0 (i2c-3)
    ```bash
    sudo i2cdetect -y -r 3  # Should show 0x0f
    ```
- [ ] Verify kernel module loads without errors
    ```bash
    sudo insmod tc358743.ko debug=3  #  <- we are stuck here, can load it but nothing shows up
    dmesg | tail
    ```
- [ ] Verify video device is created
    ```bash
    ls -l /dev/video*
    ```
- [ ] Verify NVCSI interface is ready
    ```bash
    ls -l /sys/class/video4linux/
    ```
- [ ] Verify media controller topology
    ```bash
    media-ctl -p
    ```

## I2C Bus Verification

The TC358743 HDMI to CSI-2 bridge is connected through an I2C multiplexer (TCA9548). To verify the setup:

1. First check that the camera I2C bus (i2c-2) is present:
```bash
ls -l /sys/bus/i2c/devices/
```
You should see:
- `i2c-2 -> ../../../devices/platform/bus@0/3180000.i2c/i2c-2` (Camera I2C bus)
- `2-0070` (TCA9548 multiplexer at address 0x70)
- `i2c-3` through `i2c-6` (Multiplexed buses from TCA9548)

2. Check the devices on the camera I2C bus:
```bash
sudo i2cdetect -y -r 2
```
You should see:
- `0x70` - The TCA9548 I2C multiplexer

3. Check the TC358743 on multiplexer channel 0:
```bash
sudo i2cdetect -y -r 3  # i2c-3 is mux channel 0
```
You should see:
- `0x0f` - The TC358743 HDMI to CSI bridge

We know these addresses from:
- The TCA9548 address (0x70) is defined in ARK's device tree and is standard for their camera setups
- The TC358743 address (0x0f) is defined in the Toshiba datasheet and device tree bindings
- The camera I2C bus (i2c-2) maps to address 0x3180000 in the Tegra234 SoC definition


## Reference Posts

Nvidia forum posts about the TC358743 HDMI to CSI-2 bridge:
* https://forums.developer.nvidia.com/t/how-to-enable-tc358743-on-36-3/293215/44
* https://forums.developer.nvidia.com/t/orin-nano-dev-board-8g-tc358743-4-lane-csi1-j21-1080p60-not-working/281739
* https://forums.developer.nvidia.com/t/tc358743-on-jetson-orin-nx-with-jetpack-5-x/299270/4

The file SAMPLE_tegra234-tc358743.dtsi comes from the forum post: https://forums.developer.nvidia.com/t/tc358743-on-jetson-orin-nx-with-jetpack-5-x/299270/6 but it's not clear if it was working.

There was another sample for the Jetson TX here: https://gist.github.com/olesia-kochergina/c2af863c250c748c3c58dbb7acfe84bf#file-tegra210-tc358743-dtsi 

And a generic one for xilinx: https://github.com/Xilinx/linux-xlnx/blob/master/Documentation/devicetree/bindings/media/i2c/tc358743.txt 

## Scratchpad

We want to generate the device tree as an overlay and then use the script sudo /opt/nvidia/jetson-io/config-by-hardware.py -l
 to load it.

Other notes:
* People said on the forum they had to disable imx219 and imx477 in the device tree to get this working.
* The default dtb on the device is kernel_tegra234-p3768-0000+p3767-0000-nv.dtb


Figuring out the dts:

Looking at the ARK quad camera implementation:
Their files:
tegra234-p3767-camera-p3768-ark-imx219-quad.dts - The overlay plugin
tegra234-p3768-camera-ark-quad-imx219.dtsi - Hardware specific
tegra234-camera-ark-quad-imx219.dtsi - Base camera config
Our files:
tegra234-p3767-camera-tc358743.dts - The overlay plugin
tegra234-p3768-camera-tc358743.dtsi - Hardware specific
tegra234-camera-tc358743.dtsi - Base camera config


Let's review each file:
Base config (tegra234-camera-tc358743.dtsi):
We need to verify the GPIO pin for reset-gpios is correct
We should verify the clock configuration (TEGRA234_CLK_EXTPERIPH1)
The CSI rate and link frequencies need validation
We should check if we need any additional TC358743-specific configurations from the datasheet
2. Hardware specific (tegra234-p3768-camera-tc358743.dtsi):
The I2C mux configuration looks correct based on ARK's implementation
However, we're only referencing the tc358743 node without any properties - we should probably move more hardware-specific settings here
We should verify if we need any platform-specific GPIO or power configurations
Overlay plugin (tegra234-p3767-camera-tc358743.dts):
The compatible string (JETSON_COMPATIBLE) is defined correctly
The include path for the hardware DTSI is correct
The overlay structure matches ARK's implementation
Key things to verify/add:
1. In base DTSI:
;
Need to verify this GPIO pin is available and correct for the TC358743 reset line.
Clock configuration:
;
Need to verify these clock settings match TC358743 requirements.
CSI configuration:
;
Need to validate these rates for TC358743 HDMI to CSI conversion.
Consider adding:
Power supply configuration if needed
Any required HDMI input configuration
Additional TC358743 registers that need configuration
Would you like me to research any of these specific areas in more detail?

After building and copying:
```bash
jetson@aurum-dev-af-1:~$ sudo mv tegra234-p3767-camera-tc358743.dtbo /boot/
[sudo] password for jetson:
jetson@aurum-dev-af-1:~$ sudo /opt/nvidia/jetson-io/config-by-hardware.py -l
Header 1 [default]: Jetson 40pin Header
  Available hardware modules:
  1. Adafruit SPH0645LM4H
  2. Adafruit UDA1334A
  3. FE-PI Audio V1 and Z V2
  4. ReSpeaker 4 Mic Array
  5. ReSpeaker 4 Mic Linear Array
Header 2: Jetson 24pin CSI Connector
  Available hardware modules:
  1. Camera ARK IMX219 Quad
  2. Camera ARK IMX477 Single
  3. Camera TC358743 HDMI-CSI Bridge
Header 3: Jetson M.2 Key E Slot
  No hardware configurations found!
jetson@aurum-dev-af-1:~$ sudo /opt/nvidia/jetson-io/config-by-hardware.py -n 2="Camera TC358743 HDMI-CSI Bridge"
Modified /boot/extlinux/extlinux.conf to add following DTBO entries:
/boot/tegra234-p3767-camera-tc358743.dtbo
Reboot system to reconfigure.
jetson@aurum-dev-af-1:~$
```

still seems to be trying to load the imx module even though we disabled it in the device tree overlay.
we might need to disable this as well.

We made a file: /code/third-party/ark_jetson_kernel/source_build/ark_jetson_orin_nano_nx_device_tree/tegra234-p3768-0000+p3767-0000-tc358743.dts
that includes the old one but disables the imx219 nodes.
we'll build it, then update extlinux.conf to use it.

```bash
sudo cp tegra234-p3768-0000+p3767-0000-tc358743.dtb /boot/kernel_tegra234-p3768-0000+p3767-0000-tc358743.dtb
sudo cp tegra234-p3768-0000+p3767-0000-tc358743.dtb /boot/dtb/kernel_tegra234-p3768-0000+p3767-0000-tc358743.dtb
```

change the line in extlinux.conf to use the new dtb:
FDT /boot/dtb/kernel_tegra234-p3768-0000+p3767-0000-tc358743.dtb

find ./nvidia-oot/device

Latest:
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'csi'
[sudo] password for jetson:
[    0.083293] SCSI subsystem initialized
[    0.151057] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 245)
[    6.387452] platform 13e00000.host1x:nvcsi@15a00000: Fixing up cyclic dependency with 9-0010
[    6.387478] platform 13e00000.host1x:nvcsi@15a00000: Fixing up cyclic dependency with 10-0010
[    6.387497] platform 13e00000.host1x:nvcsi@15a00000: Fixing up cyclic dependency with 11-0010
[    6.387513] platform 13e00000.host1x:nvcsi@15a00000: Fixing up cyclic dependency with 12-0010
[    6.387536] platform 13e00000.host1x:nvcsi@15a00000: Fixing up cyclic dependency with tegra-capture-vi
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'imx'
[    7.571161] imx219 9-0010: tegracam sensor driver:imx219_v2.0.6
[    7.582849] imx219 9-0010: imx219_board_setup: error during i2c read probe (-121)
[    7.587970] imx219 9-0010: board setup failed
[    7.588015] imx219: probe of 9-0010 failed with error -121
[    7.588864] imx219 10-0010: tegracam sensor driver:imx219_v2.0.6
[    7.599788] imx219 10-0010: imx219_board_setup: error during i2c read probe (-121)
[    7.604870] imx219 10-0010: board setup failed
[    7.604916] imx219: probe of 10-0010 failed with error -121
[    7.609822] imx219 11-0010: tegracam sensor driver:imx219_v2.0.6
[    7.620459] imx219 11-0010: imx219_board_setup: error during i2c read probe (-121)
[    7.625547] imx219 11-0010: board setup failed
[    7.625599] imx219: probe of 11-0010 failed with error -121
[    7.626002] imx219 12-0010: tegracam sensor driver:imx219_v2.0.6
[    7.637047] imx219 12-0010: imx219_board_setup: error during i2c read probe (-121)
[    7.642144] imx219 12-0010: board setup failed
[    7.642316] imx219: probe of 12-0010 failed with error -121
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'tc35'
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'overlay'
[    1.938589] Checking overlayfs setting...
[    1.946957] Overlayfs is disabled...
jetson@aurum-dev-af-1:~$ cat /boot/extlinux/extlinux.conf
TIMEOUT 30
DEFAULT JetsonIO

MENU TITLE L4T boot options

LABEL primary
      MENU LABEL primary kernel
      LINUX /boot/Image
      INITRD /boot/initrd
      APPEND ${cbootargs} root=PARTUUID=5c9805f0-8c5e-438c-b078-5d543df8f876 rw rootwait rootfstype=ext4 mminit_loglevel=4 console=ttyTCU0,115200 firmware_class.path=/etc/firmware fbcon=map:0 net.ifnames=0 nospectre_bhb video=efifb:off console=tty0

# When testing a custom kernel, it is recommended that you create a backup of
# the original kernel and add a new entry to this file so that the device can
# fallback to the original kernel. To do this:
#
# 1, Make a backup of the original kernel
#      sudo cp /boot/Image /boot/Image.backup
#
# 2, Copy your custom kernel into /boot/Image
#
# 3, Uncomment below menu setting lines for the original kernel
#
# 4, Reboot

# LABEL backup
#    MENU LABEL backup kernel
#    LINUX /boot/Image.backup
#    INITRD /boot/initrd
#    APPEND ${cbootargs}

LABEL JetsonIO
	MENU LABEL Custom Header Config: <CSI Camera TC358743 HDMI-CSI Bridge>
	LINUX /boot/Image
	FDT /boot/dtb/kernel_tegra234-p3768-0000+p3767-0000-nv.dtb
	INITRD /boot/initrd
	APPEND ${cbootargs} root=PARTUUID=5c9805f0-8c5e-438c-b078-5d543df8f876 rw rootwait rootfstype=ext4 mminit_loglevel=4 console=ttyTCU0,115200 firmware_class.path=/etc/firmware fbcon=map:0 net.ifnames=0 nospectre_bhb video=efifb:off console=tty0
	OVERLAYS /boot/tegra234-p3767-camera-tc358743.dtbo

After changing the extlinux.conf to our new dtb that blacklists imx:

jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'imx'
[sudo] password for jetson:
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'tc35'
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'csi'
[    0.065805] SCSI subsystem initialized
[    0.117349] Block layer SCSI generic (bsg) driver version 0.4 loaded (major 245)
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'i2c'
[    0.158707] i2c_dev: i2c /dev entries driver
[    9.847098] tegra-bpmp-i2c bpmp:i2c: failed to transfer message: -6
jetson@aurum-dev-af-1:~$ sudo i2cdetect -y -r 0
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:                         -- -- -- -- -- -- -- --
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
30: -- -- -- -- -- -- -- -- -- -- -- -- 3c -- -- --
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
70: -- -- -- -- -- -- -- --
jetson@aurum-dev-af-1:~$ sudo i2cdetect -y -r 1
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:                         -- -- -- -- -- -- -- --
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
50: UU -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
70: -- -- -- -- -- -- -- --
jetson@aurum-dev-af-1:~$ sudo i2cdetect -y -r 2
Error: Could not open file `/dev/i2c-2' or `/dev/i2c/2': No such file or directory
jetson@aurum-dev-af-1:~$ sudo i2cdetect -y -r 3
Error: Could not open file `/dev/i2c-3' or `/dev/i2c/3': No such file or directory
jetson@aurum-dev-af-1:~$ sudo i2cdetect -y -r 7
Error: Could not open file `/dev/i2c-7' or `/dev/i2c/7': No such file or directory
jetson@aurum-dev-af-1:~$ ls -l /sys/class/video4linux/
ls: cannot access '/sys/class/video4linux/': No such file or directory
jetson@aurum-dev-af-1:~$ dmesg | grep -i 'tca'
dmesg: read kernel buffer failed: Operation not permitted
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'tca'
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'mux'
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'nvcsi'
jetson@aurum-dev-af-1:~$ ls -l /proc/device-tree/ | grep -i 'tc35'
jetson@aurum-dev-af-1:~$ ls
Desktop    Downloads  Pictures  tc358743.ko                                  Templates
Documents  Music      Public    tegra234-p3768-0000+p3767-0000-tc358743.dtb  Videos
jetson@aurum-dev-af-1:~$ sudo insmod tc358743.ko
insmod: ERROR: could not insert module tc358743.ko: Unknown symbol in module

jetson@aurum-dev-af-1:~$ modinfo tc358743.ko
filename:       /home/jetson/tc358743.ko
license:        GPL
author:         Mats Randgaard <matrandg@cisco.com>
author:         Mikhail Khelik <mkhelik@cisco.com>
author:         Ramakrishnan Muthukrishnan <ram@rkrishnan.org>
description:    Toshiba TC358743 HDMI to CSI-2 bridge driver
alias:          i2c:tc358743
alias:          of:N*T*Ctoshiba,tc358743C*
alias:          of:N*T*Ctoshiba,tc358743
depends:
name:           tc358743
vermagic:       5.15.136-tegra SMP preempt mod_unload modversions aarch64
parm:           debug:debug level (0-3) (int)
jetson@aurum-dev-af-1:~$ uname -r
5.15.136-tegra

Latest update:

Built more kernel modules:
jason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source$ scp kernel/kernel-jammy-src/drivers/media/i2c/tc358743.ko jetson@192.168.1.25:~
jetson@192.168.1.25's password: 
tc358743.ko                                                                                                                       100%  189KB  10.9MB/s   00:00    
jason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source$ scp kernel/kernel-jammy-src/drivers/media/v4l2-core/*.ko jetson@192.168.1.25:~
jetson@192.168.1.25's password: 
v4l2-async.ko                                                                                                                     100%  115KB   9.9MB/s   00:00    
v4l2-dv-timings.ko                                                                                                                100%   91KB  12.1MB/s   00:00    
v4l2-fwnode.ko                                                                                                                    100%  108KB  15.2MB/s   00:00    
v4l2-h264.ko                                                                                                                      100%   43KB  11.9MB/s   00:00    
v4l2-mem2mem.ko                                                                                                                   100%  190KB  16.5MB/s   00:00    
videodev.ko                                                                                                                       100% 1626KB  21.4MB/s   00:00    
jason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source$ scp kernel/kernel-jammy-src/drivers/media/common/videobuf2/*.ko jetson@192.168.1.25:~
jetson@192.168.1.25's password: 
videobuf2-common.ko                                                                                                               100%  321KB  14.9MB/s   00:00    
videobuf2-dma-contig.ko                                                                                                           100%   88KB  14.9MB/s   00:00    
videobuf2-dma-sg.ko                                                                                                               100%   86KB  11.8MB/s   00:00    
videobuf2-memops.ko                                                                                                               100%   47KB  11.5MB/s   00:00    
videobuf2-v4l2.ko                                                                                                                 100%  137KB  19.2MB/s   00:00    
videobuf2-vmalloc.ko                                                                                                              100%   74KB  15.8MB/s   00:00    
jason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source$ scp kernel/kernel-jammy-src/drivers/media/cec/core/*.ko jetson@192.168.25.1:~
^Cjason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source$ scp kernel/kernel-jammy-src/drivers/media/cec/core/*.ko jetson@192.168.1.25:~
jetson@192.168.1.25's password: 
cec.ko   

Result:
jetson@aurum-dev-af-1:~$ ls *.ko
cec.ko       v4l2-async.ko       v4l2-fwnode.ko  v4l2-mem2mem.ko      videobuf2-dma-contig.ko  videobuf2-memops.ko  videobuf2-vmalloc.ko
tc358743.ko  v4l2-dv-timings.ko  v4l2-h264.ko    videobuf2-common.ko  videobuf2-dma-sg.ko      videobuf2-v4l2.ko    videodev.ko
-rw-rw-r-- 1 jetson jetson  356088 Nov  6 15:55 cec.ko
-rw-rw-r-- 1 jetson jetson  193088 Nov  6 15:54 tc358743.ko
-rw-rw-r-- 1 jetson jetson  117848 Nov  6 15:54 v4l2-async.ko
-rw-rw-r-- 1 jetson jetson   93584 Nov  6 15:54 v4l2-dv-timings.ko
-rw-rw-r-- 1 jetson jetson  111064 Nov  6 15:54 v4l2-fwnode.ko
-rw-rw-r-- 1 jetson jetson   44320 Nov  6 15:54 v4l2-h264.ko
-rw-rw-r-- 1 jetson jetson  194776 Nov  6 15:54 v4l2-mem2mem.ko
-rw-rw-r-- 1 jetson jetson  329016 Nov  6 15:54 videobuf2-common.ko
-rw-rw-r-- 1 jetson jetson   89944 Nov  6 15:54 videobuf2-dma-contig.ko
-rw-rw-r-- 1 jetson jetson   88400 Nov  6 15:54 videobuf2-dma-sg.ko
-rw-rw-r-- 1 jetson jetson   48024 Nov  6 15:54 videobuf2-memops.ko
-rw-rw-r-- 1 jetson jetson  139784 Nov  6 15:54 videobuf2-v4l2.ko
-rw-rw-r-- 1 jetson jetson   75464 Nov  6 15:54 videobuf2-vmalloc.ko
-rw-rw-r-- 1 jetson jetson 1665200 Nov  6 15:54 videodev.ko

To get it to load cleanly:
```bash
sudo rmmod videobuf2_dma_contig
sudo rmmod videobuf2_memops
sudo rmmod videobuf2_common
sudo rmmod videodev
sudo modprobe mc
sudo insmod videodev.ko 
sudo insmod v4l2-async.ko 
sudo insmod v4l2-dv-timings.ko 
sudo insmod v4l2-fwnode.ko 
sudo insmod videobuf2-common.ko 
sudo insmod videobuf2-v4l2.ko 
sudo insmod videobuf2-memops.ko 
sudo insmod videobuf2-vmalloc.ko 
sudo insmod cec.ko
sudo insmod tc358743.ko 
```

jetson@aurum-dev-af-1:~$ lsmod | grep tc358743
tc358743               40960  0
cec                    57344  1 tc358743
v4l2_fwnode            20480  1 tc358743
v4l2_dv_timings        40960  1 tc358743
v4l2_async             24576  2 v4l2_fwnode,tc358743
videodev              270336  4 v4l2_async,videobuf2_v4l2,videobuf2_common,tc358743
mc                     61440  4 videodev,videobuf2_v4l2,videobuf2_common,tc358743

jetson@aurum-dev-af-1:~$ sudo i2cset -y 0 0x70 0x01
Error: Write failed
jetson@aurum-dev-af-1:~$ ls -l /proc/device-tree/fragment-camera@0/
ls: cannot access '/proc/device-tree/fragment-camera@0/': No such file or directory
jetson@aurum-dev-af-1:~$ ls -l /proc/device-tree/i2c@3180000/tca9548@70/
total 0
-r--r--r-- 1 root root 12 Nov  6 16:03 compatible
-r--r--r-- 1 root root  4 Nov  6 16:03 force_bus_start
drwxr-xr-x 4 root root  0 Nov  6 16:03 i2c@0
drwxr-xr-x 3 root root  0 Nov  6 16:03 i2c@1
drwxr-xr-x 3 root root  0 Nov  6 16:03 i2c@2
drwxr-xr-x 3 root root  0 Nov  6 16:03 i2c@3
-r--r--r-- 1 root root  8 Nov  6 16:03 name
-r--r--r-- 1 root root  4 Nov  6 16:03 reg
-r--r--r-- 1 root root  4 Nov  6 16:03 skip_mux_detect

jetson@aurum-dev-af-1:~$ media-ctl --list-entities
media-ctl: unrecognized option '--list-entities'
Invalid option -?
Run media-ctl -h for help.

jetson@aurum-dev-af-1:~$ media-ctl --print-topology
Failed to enumerate /dev/media0 (-2)

sudo insmod tc358743.ko debug=3
[ 1097.344971] videodev: Linux video capture interface: v2.00
[ 1257.285314] tegra-bpmp-i2c bpmp:i2c: failed to transfer message: -6

jetson@aurum-dev-af-1:~$ ls -l /sys/class/tegra-video/
ls: cannot access '/sys/class/tegra-video/': No such file or directory
jetson@aurum-dev-af-1:~$ ls -l /sys/bus/i2c/devices/
total 0
lrwxrwxrwx 1 root root 0 Nov 21  2023 1-0050 -> ../../../devices/platform/bus@0/3160000.i2c/i2c-1/1-0050
lrwxrwxrwx 1 root root 0 Nov 21  2023 1-0057 -> ../../../devices/platform/bus@0/3160000.i2c/i2c-1/1-0057
lrwxrwxrwx 1 root root 0 Nov 21  2023 i2c-0 -> ../../../devices/platform/bpmp/bpmp:i2c/i2c-0
lrwxrwxrwx 1 root root 0 Nov 21  2023 i2c-1 -> ../../../devices/platform/bus@0/3160000.i2c/i2c-1

Since we get the error:
sudo i2cset -y 0 0x70 0x01
Error: Write failed
Looking at the errors and outputs, there are a few key issues:
The I2C mux isn't working:
sudo i2cset -y 0 0x70 0x01
Error: Write failed
This suggests either:
The I2C mux isn't powered
The I2C bus isn't configured correctly
Wrong GPIO pins for I2C
The bpmp I2C error:
:
This suggests an issue with the Tegra boot and power management processor (BPMP) I2C interface.
Looking at available I2C buses:
1
We only see i2c-0 and i2c-1, but our device tree is trying to use i2c@3180000.
Let's try:
First, verify the correct I2C bus address in the device tree:
/
Add power configuration to the TC358743 node:
;
Add explicit I2C bus configuration:

We're also going to try using 2 data lanes instead of 4, since it was mentioned on the forums.
Also matching ARK's frequency.
jason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source$ ls $DTB_PATH | grep -i 'tc35'
tegra234-p3767-camera-tc358743.dtbo
tegra234-p3768-0000+p3767-0000-tc358743.dtb
jason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source$ scp $DTB_PATH/tegra234-p3767-camera-tc358743.dtbo jetson@192.168.1.25:~
jetson@192.168.1.25's password: 
tegra234-p3767-camera-tc358743.dtbo           

For some reason it seems that extconfig.conf was overwritten maybe? IMX was loaded again:
jetson@aurum-dev-af-1:~$ sudo dmesg | grep -i 'imx'
[    7.657103] imx219 9-0010: tegracam sensor driver:imx219_v2.0.6
[    7.668360] imx219 9-0010: imx219_board_setup: error during i2c read probe (-121)
[    7.673463] imx219 9-0010: board setup failed
[    7.673532] imx219: probe of 9-0010 failed with error -121
[    7.675621] imx219 10-0010: tegracam sensor driver:imx219_v2.0.6
[    7.686253] imx219 10-0010: imx219_board_setup: error during i2c read probe (-121)
[    7.691345] imx219 10-0010: board setup failed
[    7.691399] imx219: probe of 10-0010 failed with error -121
[    7.715086] imx219 11-0010: tegracam sensor driver:imx219_v2.0.6
[    7.726120] imx219 11-0010: imx219_board_setup: error during i2c read probe (-121)
[    7.731210] imx219 11-0010: board setup failed
[    7.731262] imx219: probe of 11-0010 failed with error -121
[    7.747489] imx219 12-0010: tegracam sensor driver:imx219_v2.0.6
[    7.758690] imx219 12-0010: imx219_board_setup: error during i2c read probe (-121)
[    7.764991] imx219 12-0010: board setup failed
[    7.765047] imx219: probe of 12-0010 failed with error -121


Debugging the I2C bus:
From tegra234.dtsi (the base SoC definition):
cam_i2c: i2c@3180000 {  // This is our camera I2C bus
gen1_i2c: i2c@3160000 {
gen2_i2c: i2c@c240000 {
gen8_i2c: i2c@c250000 {

From tegra234-base-overlay.dtsi:
i2c0 = "/bus@0/i2c@3160000";  // This maps to i2c-0
i2c1 = "/bus@0/i2c@c240000";  // This maps to i2c-1
i2c2 = "/bus@0/i2c@3180000";  // This is our camera bus, should be i2c-2

cd ./source_build/Linux_for_Tegra/source/nvidia-oot/device-tree/platform/generic-dts/dtbs/
jason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source/nvidia-oot/device-tree/platform/generic-dts/dtbs$ dtc -I dtb -O dts -o temp.dts tegra234-p3768-0000+p3767-0000.dtb
jason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source/nvidia-oot/device-tree/platform/generic-dts/dtbs$ dtc -I dtb -O dts -o temp.dts tegra234-p3768-0000+p3767-0000.dtb
jason@aurum-jashton-laptop:/code/third-party/ark_jetson_kernel/source_build/Linux_for_Tegra/source/nvidia-oot/device-tree/platform/generic-dts/dtbs$ grep -A 20 "i2c@3180000" temp.dts

Next we tried explicitely enabling the i2c bus, and matched ARK's link frequency.

The IMX is booting again and I think it's because we removed it in the overlay.
Maybe it needs to be blacklisted both in the main dtb and in the overlay.

echo "blacklist imx219" | sudo tee /etc/modprobe.d/blacklist-imx219.conf
sudo update-initramfs -u
