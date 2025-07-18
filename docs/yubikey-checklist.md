# YubiKey Pre-deployment Checklist

Quick reference for what can be prepared in advance vs. what must be done on-site.

## 🔧 PRE-CONFIGURATION (Safe to do in advance)

### YubiKey Hardware Setup
- [ ] **Factory reset** (if needed) - `ykman config usb --disable-all && ykman config usb --enable-all`
- [ ] **Enable interfaces** - `ykman config usb --enable-all`
- [ ] **Change PINs** - PIV PIN/PUK from defaults
- [ ] **Configure slot 2** - `ykman otp chalresp --generate 2`
- [ ] **Record serial number** - For backup reference

### GPG Keys (if using)
- [ ] **Generate master key** - Offline environment recommended
- [ ] **Generate subkeys** - Signing, encryption, authentication
- [ ] **Transfer to YubiKey** - `gpg --edit-key -> keytocard`
- [ ] **Export public keys** - For sharing and backup
- [ ] **Export revocation cert** - Store separately

### SSH Keys (if using)
- [ ] **PIV method**: Generate RSA key in slot 9a
- [ ] **FIDO2 method**: `ssh-keygen -t ed25519-sk -O resident`
- [ ] **Extract public keys** - For server deployment

### 2FA/TOTP Accounts (if you have secrets)
- [ ] **Add accounts** - `ykman oath accounts add`
- [ ] **Test generation** - `ykman oath accounts code`
- [ ] **Export URIs** - For backup (keep secure!)

### Backup Preparation
- [ ] **Create backup storage** - Encrypted external drive
- [ ] **Export public keys** - Safe for Bitwarden notes
- [ ] **Document configuration** - Slot usage, PINs changed
- [ ] **Print QR codes** - For offline 2FA recovery

## ⚠️ ON-SITE DEPLOYMENT (Must do with target systems)

### LUKS Integration
- [ ] **Actual disk present** - Cannot pre-configure
- [ ] **Add YubiKey to LUKS** - `cryptsetup luksAddKey`
- [ ] **Test unlock** - Verify YubiKey unlocks disk
- [ ] **Backup LUKS header** - `cryptsetup luksHeaderBackup`

### System Integration
- [ ] **PAM U2F registration** - `pamu2fcfg` on target system
- [ ] **SSH key deployment** - Copy public keys to servers
- [ ] **Test system login** - Verify YubiKey authentication
- [ ] **NixOS configuration** - Apply and test changes

### Service Registration
- [ ] **GitHub 2FA** - Add security key to account
- [ ] **Google 2FA** - Register YubiKey
- [ ] **Bitwarden** - Add hardware security key
- [ ] **Other services** - Case-by-case registration

### Testing & Validation
- [ ] **LUKS unlock test** - Reboot and verify
- [ ] **SSH access test** - Connect to all servers
- [ ] **PAM login test** - System authentication
- [ ] **2FA code test** - Generate codes for all accounts
- [ ] **GPG operations** - Sign, encrypt, decrypt tests

## 📋 Deployment Phases

### Phase 1: Preparation (Secure Location)
**Time**: 2-4 hours
**Location**: Secure offline environment
**Focus**: YubiKey hardware configuration and backup setup

### Phase 2: Integration (On-Site)
**Time**: 1-2 hours per system
**Location**: Target systems
**Focus**: System integration and service registration

### Phase 3: Validation (On-Site)
**Time**: 30 minutes per system
**Location**: Target systems
**Focus**: Testing and verification

## 🎯 Efficiency Tips

### Bulk Preparation
- **Multiple YubiKeys**: Configure identically in advance
- **Standard configs**: Same PIN policies, slot usage
- **Backup YubiKeys**: Identical OATH and GPG setup

### Minimize On-Site Time
- **Pre-export** all public keys
- **Document** exact commands needed
- **Test procedures** on non-production first
- **Prepare recovery** methods in advance

### Risk Reduction
- **Never** do first setup on production
- **Always** have offline backups ready
- **Test** recovery procedures before relying on them
- **Document** every step for repeatability

## 🚨 Critical Dependencies

### Cannot Do On-Site Without:
- **Backup storage** ready and tested
- **YubiKey** pre-configured for intended use
- **Public keys** exported and ready to deploy
- **Recovery procedures** documented and tested

### Must Have Access To:
- **Target systems** with appropriate permissions
- **Service accounts** for 2FA registration
- **Secure storage** for immediate backup of on-site data
- **Network access** for service registration

## ⚡ Quick Reference Commands

### Pre-Configuration
```bash
# Basic setup
ykman info
ykman config usb --enable-all
ykman otp chalresp --generate 2

# GPG export
gpg --export --armor KEY_ID > public.asc
gpg --export-ssh-key KEY_ID > ssh.pub

# OATH backup
ykman oath accounts uri ACCOUNT > backup.txt
```

### On-Site Deployment
```bash
# LUKS integration
cryptsetup luksAddKey /dev/sdX /tmp/yk-key

# PAM registration
pamu2fcfg > ~/.config/Yubico/u2f_keys

# SSH deployment
ssh-copy-id -i key.pub user@server
```

This checklist ensures you maximize advance preparation while minimizing on-site deployment time and risk.
