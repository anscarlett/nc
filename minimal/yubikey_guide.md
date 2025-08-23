# YubiKey Setup Guide - Complete Beginner's Guide

This guide assumes you've never used a YubiKey before and walks you through everything step by step.

## 🎯 What We'll Achieve

By the end of this guide, your YubiKey will:
- ✅ Unlock your encrypted disk without typing passwords
- ✅ Store 2FA codes for websites (replacing phone apps)
- ✅ Authenticate SSH connections
- ✅ Sign Git commits securely

## 🔧 Prerequisites

### Hardware
- **YubiKey 4, 5, or 5C** (recommended models)
- **Computer with USB port** (USB-A or USB-C depending on your YubiKey)

### Software Check
```bash
# On NixOS, check if YubiKey is detected
lsusb | grep Yubico

# If not detected, try different USB port or cable
```

## 📚 Understanding YubiKey Basics

### What is a YubiKey?
A YubiKey is a small hardware security device that stores cryptographic keys and generates authentication codes. Think of it as a physical key for your digital life.

### YubiKey "Slots" Explained
Your YubiKey has different "applications" or "slots":
- **Slot 1**: Usually Yubico OTP (one-time passwords)
- **Slot 2**: We'll use for LUKS disk encryption
- **PIV**: For SSH keys and certificates  
- **OATH**: For 2FA codes (replaces Google Authenticator)
- **OpenPGP**: For GPG keys (email encryption, code signing)

## 🚀 Step-by-Step Setup

### Step 1: Install YubiKey Tools (2 minutes)

```bash
# Install YubiKey manager
nix-shell -p yubikey-manager

# Check your YubiKey
ykman info
```

You should see output like:
```
Device type: YubiKey 5C NFC
Serial number: 12345678
Firmware version: 5.4.3
```

### Step 2: Enable All Interfaces (1 minute)

```bash
# Enable all YubiKey features
ykman config usb --enable-all

# If you have NFC model
ykman config nfc --enable-all

# Verify
ykman info
```

### Step 3: Configure LUKS Disk Encryption (5 minutes)

This sets up your YubiKey to unlock your encrypted disk.

```bash
# Configure slot 2 for challenge-response
# WARNING: This overwrites anything in slot 2!
ykman otp chalresp --generate 2

# Test it works (should output a long hex string)
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"
```

**What just happened?**
- Slot 2 now contains a secret key
- When asked a "challenge" (question), it gives a specific "response" (answer)
- Your computer will use this for disk encryption

### Step 4: Set Up 2FA Accounts (10 minutes)

Replace Google Authenticator with your YubiKey.

#### Add Your First Account (GitHub example)
```bash
# Go to GitHub.com → Settings → Security → Two-factor authentication
# Choose "Authenticator app"
# GitHub shows you a QR code with a secret

# Instead of scanning with phone, click "enter this text code manually"
# Copy the secret code (looks like: JBSWY3DPEHPK3PXP)

# Add to YubiKey
ykman oath accounts add "GitHub:yourusername" JBSWY3DPEHPK3PXP

# Generate a code to verify setup
ykman oath accounts code "GitHub:yourusername"

# Enter this 6-digit code in GitHub to complete setup
```

#### Add More Accounts
```bash
# Google Account
ykman oath accounts add "Google:youremail@gmail.com" SECRET_FROM_GOOGLE

# For high-security accounts, require physical touch
ykman oath accounts add --touch "Banking:yourusername" SECRET_FROM_BANK

# List all your accounts
ykman oath accounts list

# Generate codes for all accounts
ykman oath accounts code
```

### Step 5: Critical Backup Step (15 minutes)

**⚠️ CRITICAL**: This step prevents lockout if you lose your YubiKey.

#### Create Backup Storage
```bash
# You need an encrypted USB drive for backups
# Insert USB drive and encrypt it (adjust device path):
sudo cryptsetup luksFormat /dev/sdb1
sudo cryptsetup luksOpen /dev/sdb1 backup
sudo mkfs.ext4 /dev/mapper/backup
sudo mkdir -p /mnt/backup
sudo mount /dev/mapper/backup /mnt/backup
```

#### Backup Your 2FA Secrets
```bash
# Export OATH accounts (KEEP THIS SECURE!)
mkdir -p /tmp/yubikey-backup
for account in $(ykman oath accounts list); do
    echo "=== $account ===" >> /tmp/yubikey-backup/oath-backup.txt
    ykman oath accounts uri "$account" >> /tmp/yubikey-backup/oath-backup.txt
    echo "" >> /tmp/yubikey-backup/oath-backup.txt
done

# Copy to encrypted backup drive
sudo cp /tmp/yubikey-backup/oath-backup.txt /mnt/backup/

# Record YubiKey info
ykman info > /tmp/yubikey-backup/device-info.txt
sudo cp /tmp/yubikey-backup/device-info.txt /mnt/backup/

# Clean up and unmount
shred -vfz /tmp/yubikey-backup/*
rmdir /tmp/yubikey-backup
sudo umount /mnt/backup
sudo cryptsetup luksClose backup
```

#### Store Safe Information in Password Manager
Add a note in Bitwarden with:
```
YubiKey Configuration
- Serial: 12345678 (from ykman info)
- Slot 2: HMAC-SHA1 challenge-response for LUKS
- Accounts: GitHub, Google, Banking (without secrets!)
- Backup location: Encrypted USB drive in safe
```

### Step 6: Configure Your NixOS System (10 minutes)

#### Set Your Disk Device
Edit `hosts/example/host.nix`:
```nix
(import ../../modules/disko.nix {
  disk = "/dev/nvme0n1";  # CHANGE TO YOUR ACTUAL DISK!
  luksName = "cryptroot";
  enableYubikey = true;
})
```

**How to find your disk:**
```bash
# List all disks
lsblk
fdisk -l

# Look for your main disk (usually /dev/nvme0n1 or /dev/sda)
```

#### Set Your User Password
```bash
# Generate password hash
mkpasswd -m sha-512 yourpassword

# Add to hosts/example/host.nix:
users.users.example.hashedPassword = "GENERATED_HASH_HERE";
```

### Step 7: Deploy System (15 minutes)

```bash
# Build and deploy
sudo nixos-rebuild switch --flake .#example

# If this is a fresh install, you might need:
sudo nixos-install --flake .#example
```

### Step 8: Add YubiKey to LUKS (ON-SITE ONLY)

**⚠️ This must be done on the actual system with the encrypted disk:**

```bash
# Find your LUKS device
lsblk | grep crypt

# Usually something like /dev/nvme0n1p2
LUKS_DEVICE="/dev/nvme0n1p2"  # ADJUST THIS!

# Create challenge-response key
CHALLENGE="unlock-$(hostname)"
RESPONSE=$(ykman otp calculate 2 "$(echo -n "$CHALLENGE" | xxd -p)")

# Convert to binary key
echo -n "$RESPONSE" | xxd -r -p > /tmp/yk-key

# Add to LUKS (you'll need your current password)
sudo cryptsetup luksAddKey "$LUKS_DEVICE" /tmp/yk-key

# Secure cleanup
shred -vfz /tmp/yk-key

# Test unlock works
sudo cryptsetup luksDump "$LUKS_DEVICE"
```

## 🎉 You're Done! Daily Usage

### Generate 2FA Codes
```bash
# See all accounts
ykman oath accounts list

# Generate specific code
ykman oath accounts code "GitHub:yourusername"

# Generate all codes
ykman oath accounts code
```

### Boot Your System
1. **Power on** → LUKS prompt appears
2. **Insert YubiKey** if not already connected
3. **Touch YubiKey** when LED blinks
4. **System unlocks** and boots normally

### SSH Authentication (Optional Advanced Setup)
```bash
# Generate SSH key on YubiKey
ssh-keygen -t ed25519-sk -O resident -f ~/.ssh/id_yubikey

# Copy to servers
ssh-copy-id -i ~/.ssh/id_yubikey.pub user@server

# Use with touch verification
ssh user@server  # Will require YubiKey touch
```

## 🆘 Emergency Recovery

### If YubiKey is Lost
1. **Don't panic** - you have backups
2. **Use disk password** to unlock system
3. **Get new YubiKey**
4. **Restore OATH accounts** from encrypted backup
5. **Re-register** with websites

### If You Forget LUKS Password
1. **Boot from NixOS ISO**
2. **Try YubiKey unlock** (if YubiKey still works)
3. **Use LUKS header backup** if available
4. **Restore from system backups**

### Recovery Commands
```bash
# Remove lost YubiKey from LUKS
sudo cryptsetup luksKillSlot /dev/nvme0n1p2 1  # Slot 1 is usually YubiKey

# Restore OATH accounts to new YubiKey
# Mount encrypted backup drive first, then:
while read line; do
    if [[ $line == ykman* ]]; then
        eval "$line"
    fi
done < oath-backup.txt
```

## 🔐 Security Best Practices

### Physical Security
- **Keep YubiKey with you** - attach to keychain
- **Don't leave in computer** unattended
- **Consider backup YubiKey** with identical setup

### Digital Security
- **Backup secrets securely** - encrypted storage only
- **Test recovery procedures** before relying on them
- **Update backup regularly** when adding new accounts
- **Keep device info documented** but separate from secrets

### PIN Management
Some YubiKey features use PINs:
```bash
# PIV PIN (for SSH keys) - default is 123456
ykman piv access change-pin

# OATH password (for 2FA protection)
ykman oath access change-password
```

## 🚨 Common Mistakes to Avoid

1. **Not backing up OATH secrets** - You'll be locked out of accounts
2. **Losing LUKS password** - Keep it separate from YubiKey
3. **Not testing recovery** - Try it on a test system first
4. **Leaving YubiKey unattended** - Physical security matters
5. **Using same YubiKey for everything** - Consider separate keys for different risk levels

## 🔍 Troubleshooting

### YubiKey Not Detected
```bash
# Check USB
lsusb | grep Yubico

# Try different port/cable
# Check if cap is on properly
# Restart udev: sudo udevadm control --reload
```

### LUKS Unlock Fails
```bash
# Check YubiKey response
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"

# Check LUKS slots
sudo cryptsetup luksDump /dev/nvme0n1p2

# Fall back to password if needed
```

### 2FA Codes Don't Work
```bash
# Check time sync (important for TOTP)
sudo ntpdate -s time.nist.gov

# Regenerate code
ykman oath accounts code "Account:user"
```

## 📞 Getting Help

- **NixOS Manual**: https://nixos.org/manual/
- **YubiKey Docs**: https://developers.yubico.com/
- **This repository**: Open an issue for questions

Remember: Security is a process, not a destination. Start simple and add features gradually!