# Quick Start Guide

## 🚀 Get Running in 15 Minutes

### 1. Clone Repository
```bash
git clone <this-repo> minimal-nixos
cd minimal-nixos
```

### 2. YubiKey Basic Setup
```bash
# Install tools
nix-shell -p yubikey-manager

# Check YubiKey
ykman info

# Enable all features
ykman config usb --enable-all

# Configure for LUKS (OVERWRITES slot 2!)
ykman otp chalresp --generate 2

# Test
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"
```

### 3. Copy Example Configuration
```bash
# Copy and rename example configs
cp -r hosts/example hosts/mylaptop
cp -r users/example users/myuser
```

### 4. Customize Configuration

Edit `hosts/mylaptop/host.nix`:
- Change disk device: `disk = "/dev/nvme0n1";`
- Change LUKS name: `luksName = "cryptlaptop";`

Edit `users/myuser/user.nix`:
- Change name: `userName = "Your Real Name";`
- Change email: `userEmail = "your@email.com";`

### 5. Set Password
```bash
# Generate hash
nix-shell -p mkpasswd --run 'mkpasswd -m sha-512 yourpassword'

# Add to hosts/mylaptop/host.nix:
users.users.myuser.hashedPassword = "PASTE_HASH_HERE";
```

### 6. Deploy
```bash
sudo nixos-rebuild switch --flake .#mylaptop
```

## 🔑 Essential YubiKey Commands

### Daily 2FA Usage
```bash
# List accounts
ykman oath accounts list

# Get code for specific account  
ykman oath accounts code "GitHub:username"

# Get all codes
ykman oath accounts code
```

### Add New 2FA Account
```bash
# Website shows you QR code, click "enter manually" for secret
ykman oath accounts add "ServiceName:username" SECRET_FROM_WEBSITE

# For sensitive accounts, require touch
ykman oath accounts add --touch "Banking:username" SECRET
```

### Check YubiKey Status
```bash
# Basic info
ykman info

# Check what's configured
ykman otp info    # Challenge-response slots
ykman oath list   # 2FA accounts
ykman piv info    # SSH/certificates
```

## 🛠️ System Management

### Build Commands
```bash
# Test configuration
nix flake check

# Build without switching
nixos-rebuild build --flake .#mylaptop

# Switch to new configuration
sudo nixos-rebuild switch --flake .#mylaptop

# Rollback if needed
sudo nixos-rebuild switch --rollback
```

### Check Disk Encryption
```bash
# Check LUKS status
sudo cryptsetup status /dev/mapper/cryptroot

# Check YubiKey LUKS key
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep "Key Slot"

# Test YubiKey response
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"
```

### Backup Important Data
```bash
# Backup LUKS header (CRITICAL!)
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file luks-header.img

# Backup 2FA secrets (KEEP SECURE!)
ykman oath accounts uri "GitHub:username" > github-backup.txt

# Store on encrypted USB drive, NOT in cloud!
```

### Recovery Commands
```bash
# Boot without YubiKey (use password)
# At LUKS prompt, just type your disk password

# Remove lost YubiKey from LUKS
sudo cryptsetup luksKillSlot /dev/nvme0n1p2 1

# Restore LUKS header if disk corrupted
sudo cryptsetup luksHeaderRestore /dev/nvme0n1p2 --header-backup-file luks-header.img
```

## 📚 Next Steps

- **Read docs/YUBIKEY.md** for complete YubiKey features
- **See docs/PRIVATE.md** for work/private repository setup
- **Test everything** on a VM first before production use

## 🆘 Emergency Contact

If you're locked out:
1. Try password at LUKS prompt
2. Boot from NixOS ISO to recover
3. Use backup YubiKey if configured
4. Restore from LUKS header backup if needed