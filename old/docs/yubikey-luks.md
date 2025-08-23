# YubiKey LUKS Setup Guide - NixOS Installation

This guide explains how to set up YubiKey for LUKS disk encryption unlock during a fresh NixOS installation when this is your only computer available.

## Prerequisites

1. **YubiKey device** (YubiKey 4/5 series recommended)
2. **NixOS ISO** booted on the target machine
3. **This flake repository** (cloned or downloaded to the installer)
4. **Target disk** identified for installation

## Installation Process Overview

Since this is your only computer and it's not yet configured, we'll:
1. Prepare YubiKey in the NixOS installer environment
2. Use disko to partition and encrypt the disk with YubiKey support
3. Install NixOS with YubiKey unlock configured
4. Test the YubiKey unlock after installation

## Step 1: Boot NixOS Installer and Prepare Environment

```bash
# Boot from NixOS ISO
# Connect to internet (wifi-password or ethernet)
sudo systemctl start wpa_supplicant  # if using WiFi

# Install required packages in the installer environment
nix-shell -p git yubikey-manager cryptsetup

# Clone this repository (or copy from USB drive)
git clone <this-repository-url> /tmp/nc
cd /tmp/nc
```

## Step 2: Prepare YubiKey

Since you can't prepare the YubiKey elsewhere, we'll do it in the installer:

```bash
# Ensure YubiKey is detected
lsusb | grep Yubico

# Check current YubiKey configuration
ykman info
ykman otp info

# Configure slot 2 for HMAC-SHA1 challenge-response
# This will OVERWRITE any existing configuration in slot 2!
ykman otp chalresp --generate 2

# Verify configuration
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)" # Should return a hex response
```

**⚠️ IMPORTANT:** This will overwrite YubiKey slot 2. If you use slot 2 for other purposes, consider using a different YubiKey or accepting that this will replace existing configuration.

## Step 3: Identify Target Disk and Configure Installation

```bash
# List available disks
lsblk -f
fdisk -l

# Identify your target disk (e.g., /dev/nvme0n1, /dev/sda)
TARGET_DISK="/dev/nvme0n1"  # ADJUST THIS TO YOUR DISK!

# Choose your configuration based on the host
# For Legion laptop:
HOST_CONFIG="home-legion"
# For CT laptop:
# HOST_CONFIG="ct-laptop"
```

## Step 4: Install NixOS with Disko and YubiKey Support

```bash
# Enable flakes in the installer
export NIX_CONFIG="experimental-features = nix-command flakes"

# Build the disko script for your chosen configuration
nix build .#nixosConfigurations.${HOST_CONFIG}.config.system.build.diskoScript

# Review the disko configuration before proceeding
nix eval .#nixosConfigurations.${HOST_CONFIG}.config.disko.devices --json | jq .

# ⚠️ WARNING: This will DESTROY ALL DATA on the target disk!
# Make sure you have the right disk and any important data is backed up!
sudo $(readlink result) --mode disko ${TARGET_DISK}

# Mount the filesystems
sudo mkdir -p /mnt
sudo mount /dev/mapper/cryptroot /mnt  # For legion
# sudo mount /dev/mapper/cryptlaptop /mnt  # For CT laptop
sudo mkdir -p /mnt/boot
sudo mount /dev/${TARGET_DISK}p1 /mnt/boot  # Adjust partition number if needed

# Generate initial NixOS configuration
sudo nixos-generate-config --root /mnt

# Replace the generated configuration with our flake-based one
sudo rm /mnt/etc/nixos/configuration.nix
sudo cp -r /tmp/nc /mnt/etc/nixos/
cd /mnt/etc/nixos/nc

# Install NixOS using our flake
sudo nixos-install --flake .#${HOST_CONFIG}
```

## Step 5: Configure YubiKey LUKS Key

After NixOS installation but before rebooting:

```bash
# Add YubiKey challenge-response to LUKS
# The LUKS container should still be open from installation
LUKS_DEVICE="${TARGET_DISK}p2"  # Usually partition 2, adjust if needed

# Create a challenge-response key for LUKS
CHALLENGE="nixos-luks-$(date +%s)"
RESPONSE=$(ykman otp calculate 2 "$(echo -n "$CHALLENGE" | xxd -p)")

# Convert the response to binary and add it as a LUKS key
echo -n "$RESPONSE" | xxd -r -p > /tmp/yk-luks-key

# Add the YubiKey key to LUKS slot 1 (slot 0 is your password)
sudo cryptsetup luksAddKey ${LUKS_DEVICE} /tmp/yk-luks-key --key-slot 1

# Securely delete the temporary key file
sudo shred -vfz /tmp/yk-luks-key

# Verify the key was added
sudo cryptsetup luksDump ${LUKS_DEVICE} | grep "Key Slot"
```

## Step 6: Test and Finalize

```bash
# Set a root password for initial access
sudo nixos-enter --root /mnt
passwd root  # Set a temporary root password
exit

# Unmount and prepare for reboot
sudo umount -R /mnt
sudo cryptsetup close cryptroot  # or cryptlaptop for CT

# Remove the installer USB/CD and reboot
reboot
```

## Step 7: Post-Installation Testing

After rebooting:

1. **Insert YubiKey** before the LUKS prompt appears
2. **Touch YubiKey** when the LED blinks (challenge-response prompt)
3. **System should unlock** and continue booting
4. **If YubiKey fails**, you can still use your LUKS password

## Troubleshooting Installation Issues

### YubiKey not detected during installation
```bash
# In installer, check USB subsystem
lsusb
dmesg | grep -i yubi

# Reload USB modules if needed
sudo modprobe -r usbhid
sudo modprobe usbhid
```

### Disko fails
```bash
# Check if disk is busy
lsof ${TARGET_DISK}*
sudo fuser -km ${TARGET_DISK}*

# Unmount any existing filesystems
sudo umount ${TARGET_DISK}* 2>/dev/null || true
```

### Installation fails
```bash
# Check available space
df -h /mnt

# Review installation logs
journalctl -f
```

### YubiKey unlock fails after installation
1. **Boot from NixOS ISO again**
2. **Unlock with password**: `cryptsetup open ${TARGET_DISK}p2 cryptroot`
3. **Mount and chroot**: 
   ```bash
   sudo mount /dev/mapper/cryptroot /mnt
   sudo mount ${TARGET_DISK}p1 /mnt/boot
   sudo nixos-enter --root /mnt
   ```
4. **Debug YubiKey configuration** or **re-add the key**

## Host-Specific Configuration Details

### Legion (home-legion)
- **Target disk variable**: Usually `/dev/nvme0n1`
- **LUKS name**: `cryptroot`
- **User**: `adrian-home`
- **Hibernation**: Enabled (no swap file, hibernation to LUKS)

### CT Laptop (ct-laptop)  
- **Target disk variable**: Usually `/dev/nvme0n1` or `/dev/sda`
- **LUKS name**: `cryptlaptop`
- **User**: `adrianscarlett-ct`
- **Hibernation**: Enabled with 32GB swap

## Security Notes for Fresh Installation

1. **Physical security**: Keep YubiKey with you during installation
2. **Backup LUKS header**: After installation: `cryptsetup luksHeaderBackup`
3. **Document your setup**: Save challenge string and configuration details
4. **Test unlock immediately**: Don't leave the site until YubiKey unlock works
5. **Keep recovery options**: Always have password backup and rescue plan

## Emergency Recovery

If YubiKey is lost or broken:
1. **Boot from NixOS ISO**
2. **Unlock with password**: `cryptsetup open ${TARGET_DISK}p2 cryptroot`
3. **Remove YubiKey key slot**: `cryptsetup luksKillSlot ${TARGET_DISK}p2 1`
4. **Add new YubiKey or remove YubiKey support** from configuration

This installation method ensures you can set up YubiKey LUKS unlock even when this is your only available computer during the NixOS installation process.

## Host Configurations

### Legion (home/legion)
- **Disk**: `/dev/disk/by-id/legion-disk`
- **LUKS name**: `cryptroot`
- **YubiKey**: Enabled
- **Impermanence**: Enabled

### CT Laptop (ct/laptop)
- **Disk**: `/dev/disk/by-id/ct-laptop-disk`
- **LUKS name**: `cryptlaptop`
- **YubiKey**: Enabled
- **Impermanence**: Enabled

## Troubleshooting

### YubiKey not detected
```bash
# Check if YubiKey is visible
lsusb | grep Yubico

# Check udev rules
udevadm info -a -p $(udevadm info -q path -n /dev/bus/usb/XXX/YYY)
```

### LUKS unlock fails
1. **Check key slot**: `sudo cryptsetup luksDump /dev/sdXY`
2. **Test YubiKey**: `ykman otp calculate 2 "$(echo -n 'hello' | xxd -p)"`
3. **Fallback to password**: Type your LUKS password at the prompt

### Emergency recovery
If YubiKey fails and you lose your password:
1. **Boot from NixOS ISO**
2. **Use backup key** (if configured)
3. **Restore from backup** (if available)

## Security Notes

1. **Backup your LUKS header**: `cryptsetup luksHeaderBackup`
2. **Keep backup passphrase** in a secure location
3. **Test unlock process** before relying on it
4. **YubiKey touch required** for additional security

## Advanced Configuration

### Multiple YubiKeys
To add multiple YubiKeys for redundancy:

```bash
# Add second YubiKey to different slot
sudo cryptsetup luksAddKey /dev/sdXY --key-slot 2
```

### Custom challenge
You can customize the challenge string in the disko preset if needed.

## Integration with SOPS/Age

The systems also support SOPS secrets stored in the encrypted `/persist/secrets` subvolume, which is unlocked alongside the main LUKS container.
