# YubiKey Quick Setup Guide

Get your YubiKey configured for essential security features in 30 minutes.

## 🎯 What This Covers

This quick guide sets up:
- ✅ Basic YubiKey configuration
- ✅ Challenge-response for LUKS (slot 2)
- ✅ Basic 2FA/TOTP accounts
- ✅ Essential backups

**Not covered here**: GPG keys, advanced SSH, PAM authentication
**For full setup**: See [YubiKey Overview](yubikey-overview.md)

## 🔧 Prerequisites

```bash
# Install required tools
nix-shell -p yubikey-manager

# Verify YubiKey detection
ykman info
```

## 📝 Pre-Setup Checklist

**🔒 CRITICAL**: Set up backup storage FIRST
- [ ] Encrypted external drive ready
- [ ] Bitwarden account for notes
- [ ] Physical safe for printed backups (optional)

## ⚡ Quick Setup Steps

### 1. Basic YubiKey Configuration (5 min)
🔧 **PRE-CONFIGURATION**: Can be done anywhere

```bash
# Record YubiKey info in Bitwarden note
ykman info

# Enable all interfaces
ykman config usb --enable-all
ykman config nfc --enable-all  # if NFC model

# 📝 BACKUP: Add to Bitwarden note
# "YubiKey Serial: XXXXX, Model: YubiKey 5C NFC"
```

### 2. Challenge-Response Setup (5 min)
🔧 **PRE-CONFIGURATION**: Essential for LUKS

```bash
# Configure slot 2 for challenge-response
ykman otp chalresp --generate 2

# Test it works
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"

# 📝 BACKUP: Add to Bitwarden note
# "Slot 2: HMAC-SHA1 challenge-response configured for LUKS"
```

### 3. Essential 2FA Accounts (10 min)
🔧 **PRE-CONFIGURATION**: If you have account access

```bash
# Add your most important accounts
ykman oath accounts add "GitHub:yourusername" SECRET_KEY
ykman oath accounts add "Google:youremail" SECRET_KEY

# For high-security accounts, require touch
ykman oath accounts add --touch "Banking:yourusername" SECRET_KEY

# Test generating codes
ykman oath accounts code

# 🔒 BACKUP: Export for emergency recovery
ykman oath accounts uri "GitHub:yourusername" > github-backup.txt
# Store this file on encrypted external drive!
```

### 4. Essential Backups (10 min)
🔒 **CRITICAL**: Don't skip this step

```bash
# Create backup directory
mkdir -p ~/yubikey-backup

# Export OATH accounts
for account in $(ykman oath accounts list); do
    echo "=== $account ===" >> ~/yubikey-backup/oath-backup.txt
    ykman oath accounts uri "$account" >> ~/yubikey-backup/oath-backup.txt
    echo "" >> ~/yubikey-backup/oath-backup.txt
done

# 🔒 BACKUP: Copy to encrypted external drive
cp ~/yubikey-backup/oath-backup.txt /path/to/encrypted/drive/

# 📝 BACKUP: Add non-secrets to Bitwarden
# - YubiKey serial number
# - Slot 2 configured for LUKS
# - Account names (without secret keys)
```

## 🚀 You're Ready For:

### Immediate Use
- **2FA codes**: `ykman oath accounts code`
- **LUKS setup**: Ready for [LUKS guide](YUBIKEY-LUKS.md)

### Next Steps (Optional)
- **SSH Keys**: Follow [SSH guide](yubikey-ssh.md)
- **GPG Setup**: Follow [GPG guide](yubikey-gpg.md)  
- **System Login**: Follow [PAM guide](yubikey-pam.md)

## 🛠️ Daily Usage

```bash
# Generate 2FA codes
ykman oath accounts code "GitHub:yourusername"

# List all accounts
ykman oath accounts list

# Check YubiKey status
ykman info
```

## ⚠️ Important Notes

### Security
- **Keep backup files secure** - They contain 2FA secret keys
- **Test recovery** - Make sure you can restore from backups
- **Physical security** - Don't leave YubiKey unattended

### Limitations of Quick Setup
- No GPG keys (need separate setup)
- No SSH integration (need separate setup)
- No system login integration (need PAM setup)
- Basic OATH only (no advanced features)

## 🆘 Emergency Recovery

If YubiKey is lost:
1. **Don't panic** - you have backups
2. **Get new YubiKey**
3. **Restore OATH accounts** from backup files
4. **Re-register** with websites as needed

## 📚 Next Steps

**Ready for more?** Check out:
- [LUKS Disk Encryption](YUBIKEY-LUKS.md) - Unlock disks with YubiKey
- [SSH Authentication](yubikey-ssh.md) - SSH keys on YubiKey
- [Full Setup Guide](yubikey-overview.md) - Complete security suite

**Having issues?** See [Troubleshooting](yubikey-troubleshooting.md)
