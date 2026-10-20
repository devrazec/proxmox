# Install MacOS on Proxmox

https://github.com/luchina-gabriel/OSX-PROXMOX

/bin/bash -c "$(curl -fsSL https://install.osx-proxmox.com)"

or

https://klabsdev.com/definitive-guide-to-running-macos-in-proxmox/

VM ID: (any empty ID)
Name: MacOS
RAM: 4096 MB, Ballooning: OFF
Processor: CPU Cores: 4, Sockets: 1, Type: Default (kvm64)
BIOS: OVMF (UEFI)
Display: VMware compatible
Machine: q35
SCSI Controller: VirtIO SCSI
Hard Disk (ide0): local:iso/OpenCore-v21.iso,cache=unsafe,media=disk,size=150M
Hard Disk (ide2): local:iso/macOS-Sonoma-14.1.1.iso,cache=unsafe,media=disk,size=16000M
Hard Disk (sata0): local-lvm:vm-108-disk-5,cache=unsafe,size=128G
Network: VMware vmxnet3, Bridge: vmbr0, Firewall: 0
EFI Disk: Enabled
Pre-Enroll Keys: OFF
Guest OS Type: Other
QEMU Guest Agent: Enabled
TPM: OFF

- nano /etc/pve/qemu-server/108.conf and add these lines

- Default

agent: 1

args: -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device usb-kbd,bus=ehci.0,port=2 -device usb-mouse,bus=ehci.0,port=3 -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off -cpu Haswell-noTSX,stepping=3,kvm=on,vendor=GenuineIntel,+kvm_pv_unhalt,+kvm_pv_eoi,+hypervisor,+invtsc,+vmx,vmware-cpuid-freq=on

or

args: -device isa-applesmc,osk="ourhardworkbythesewordsguardedpleasedontsteal(c)AppleComputerInc" -smbios type=2 -device usb-kbd,bus=ehci.0,port=2 -global nec-usb-xhci.msi=off -global ICH9-LPC.acpi-pci-hotplug-with-bridge-support=off -cpu host,vendor=GenuineIntel,+invtsc,+hypervisor,kvm=on,vmware-cpuid-freq=on

autostart: 0
balloon: 0
bios: ovmf
boot: order=ide0;sata0
cores: 4
efidisk0: local-lvm:vm-108-disk-1,efitype=4m,size=4M
ide0: local:iso/OpenCore-v21.iso,cache=unsafe,media=disk,size=150M
ide2: local:iso/macOS-Sonoma-14.1.1.iso,cache=unsafe,media=disk,size=16000M
machine: q35
memory: 4096
meta: creation-qemu=9.2.0,ctime=1792525893
name: MaxOS
net0: vmxnet3=BC:24:11:EB:49:7B,bridge=vmbr0
numa: 0
ostype: other
sata0: local-lvm:vm-108-disk-2,cache=none,discard=on,size=128G
scsihw: virtio-scsi-pci
smbios1: uuid=3c883d41-7e37-4b5a-8677-483808af94bf
sockets: 1
vga: vmware

- Change

ide0: local:iso/OpenCore-v21.iso,cache=unsafe,media=disk,size=150M

ide2: local:iso/macOS-Sonoma-14.1.1.iso,cache=unsafe,media=disk,size=16000M

ide2: local:iso/MacOSHighSierra.iso,cache=unsafe,media=disk,size=8000M

sata0: local-lvm:vm-108-disk-2,cache=none,discard=on,size=128G

- After boot select the UEFI location by arrow

fs0:

- Run the UEFI boot file by typing

System\Library\CoreServices\boot.efi

- Once booted into MacOS Recovery, choose "Disk Utility"

Click "Erase", Format APFS, Schema GUID Partition Map

Exit Disk Utility and choose the "Install macOS Sonoma"

- Download images fromm

https://cdn.klabsdev.com/MacImages/macOS-Tahoe-Beta-26.0.iso?ref=klabsdev.com
https://cdn.klabsdev.com/MacImages/macOS-Sequoia-15.4.iso?ref=klabsdev.com
https://cdn.klabsdev.com/MacImages/macOS-Ventura-13.6.3.iso?ref=klabsdev.com
https://cdn.klabsdev.com/MacImages/macOS-Monterey-12.7.1.iso?ref=klabsdev.com
https://archive.org/download/mac-os-high-sierra-iso/MacOSHighSierra.iso

or

https://archive.org/details/operatingsystemcds?page=2

Windows Server 2003 (English)
Product Key: M6RJ9-TBJH3-9DDXM-4VX9Q-K8M8M
https://archive.org/download/en_win_srv_2003_r2_standard_with_sp2_cd1_X13-04790/en_win_srv_2003_r2_standard_with_sp2_cd1_X13-04790.iso

This is the original Windows Server 2003 Standard Edition and x64 Edition. 
Serial: BXD88-QGH3V-XG44M-MDXGW-CBYQY
https://archive.org/details/windows-server-2003-standard-edition-with-sp2