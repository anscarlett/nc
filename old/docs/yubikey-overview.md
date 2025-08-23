# YubiKey Setup Guide - Overview

This is the main overview document for setting up YubiKey security on NixOS. The full setup has been broken into focused guides for easier navigation.

## 📚 Document Structure

### **Quick Start**
- 🚀 [YubiKey Quick Setup](yubikey-quick-setup.md) - Essential setup in 30 minutes
- 📋 [Pre-deployment Checklist](yubikey-checklist.md) - What to prepare vs. what to do on-site

### **Detailed Guides**
- 🔐 [LUKS Disk Encryption](YUBIKEY-LUKS.md) - Full disk encryption with YubiKey unlock
- 🔑 [SSH Authentication](yubikey-ssh.md) - SSH keys stored on YubiKey (PIV & FIDO2)
- 👤 [User Authentication (PAM)](yubikey-pam.md) - System login with YubiKey
- 🔢 [2FA/TOTP Setup](yubikey-2fa.md) - YubiKey as authenticator app replacement
- 📧 [GPG Keys](yubikey-gpg.md) - Signing, encryption, and authentication

### **Backup & Security**
- 💾 [Backup Strategy](yubikey-backup.md) - What to backup and where to store it
- 🗑️ [Security Cleanup](yubikey-cleanup.md) - What to delete after setup
- 🛠️ [Troubleshooting](yubikey-troubleshooting.md) - Common issues and solutions

## 🎯 Choose Your Path

### **I want everything set up (comprehensive security)**
1. Read [Pre-deployment Checklist](yubikey-checklist.md)
2. Follow [Backup Strategy](yubikey-backup.md) first
3. Work through each detailed guide
4. Finish with [Security Cleanup](yubikey-cleanup.md)

### **I just want LUKS disk encryption**
1. [YubiKey Quick Setup](yubikey-quick-setup.md) → Basic YubiKey prep
2. [LUKS Disk Encryption](YUBIKEY-LUKS.md) → Full LUKS setup
3. [Backup Strategy](yubikey-backup.md) → Just LUKS sections

### **I want SSH + 2FA only**
1. [YubiKey Quick Setup](yubikey-quick-setup.md) → Basic YubiKey prep
2. [SSH Authentication](yubikey-ssh.md) → SSH key setup
3. [2FA/TOTP Setup](yubikey-2fa.md) → Authenticator setup

### **I want the full security suite**
1. [GPG Keys](yubikey-gpg.md) → Start with GPG master key
2. [SSH Authentication](yubikey-ssh.md) → SSH via GPG or FIDO2
3. [LUKS Disk Encryption](YUBIKEY-LUKS.md) → Disk encryption
4. [User Authentication (PAM)](yubikey-pam.md) → System login
5. [2FA/TOTP Setup](yubikey-2fa.md) → Website 2FA

## 🚨 Critical First Steps

Before starting any setup:

1. **Read [Backup Strategy](yubikey-backup.md)** - Understand what needs backing up
2. **Prepare secure storage** - Get encrypted external drive and plan offline storage
3. **Test on non-production** - Try everything on a VM or test system first
4. **Have recovery plan** - Know how to recover if things go wrong

## 🔧 Prerequisites

### Hardware
- YubiKey 4/5 series (recommended)
- USB-A or USB-C depending on your devices
- NFC support (optional, for mobile use)

### Software (NixOS)
```bash
nix-shell -p yubikey-manager libfido2 gnupg pinentry-gtk2 pam_u2f cryptsetup
```

### Knowledge Level
- **Beginner**: Start with [Quick Setup](yubikey-quick-setup.md)
- **Intermediate**: Jump to specific guides you need
- **Advanced**: Use this as reference, customize as needed

## 🛡️ Security Model

This setup provides:
- **Disk encryption** without passwords (YubiKey touch)
- **SSH authentication** via hardware keys
- **System login** via YubiKey touch
- **2FA for websites** without phone apps
- **GPG signing/encryption** for secure communications
- **Hardware-backed** password manager integration

## 📞 Support

If you run into issues:
1. Check [Troubleshooting](yubikey-troubleshooting.md)
2. Verify your backup strategy is working
3. Test on non-production systems first
4. Consider starting with simpler setup and adding features gradually

Remember: Security is a journey, not a destination. Start with what you need most and expand gradually.
