# YubiKey Security Backup Documentation

## 📋 Device Information
- **YubiKey Model**: ________________
- **Serial Number**: ________________
- **Firmware Version**: ________________
- **Purchase Date**: ________________
- **Setup Date**: ________________

## 🔐 Configuration Lock & PINs

### Configuration Lock Code
- **Lock Code**: ________________
- **Set Date**: ________________
- **Notes**: Store this in Bitwarden - required to modify YubiKey configuration

### PIV Application
- **PIV PIN**: ________________ (Default was: 123456)
- **PIV PUK**: ________________ (Default was: 12345678)
- **PIN Change Date**: ________________
- **Attempts Remaining**: PIN: ___ / PUK: ___

### OATH Application
- **OATH Password**: ________________
- **Set Date**: ________________
- **Notes**: Required to access TOTP codes

## 🔑 SSH Configuration

### Method Used: ☐ PIV/PKCS#11  ☐ FIDO2/WebAuthn

### PIV Method (if used)
- **Key Slot**: ________________ (typically 9a)
- **Algorithm**: ________________ (typically RSA2048)
- **Certificate Subject**: ________________
- **SSH Public Key Location**: ________________

### FIDO2 Method (if used)
- **Key Type**: ☐ ed25519-sk ☐ ecdsa-sk
- **Resident Key**: ☐ Yes ☐ No
- **Verification Required**: ☐ Yes ☐ No
- **SSH Public Key Location**: ________________

## 💾 LUKS Disk Encryption

### YubiKey LUKS Setup
- **Slot Used**: ________________ (typically slot 2)
- **Challenge String**: ________________
- **LUKS Device**: ________________ (e.g., /dev/nvme0n1p2)
- **LUKS UUID**: ________________
- **Two-Factor Mode**: ☐ Yes ☐ No

### Backup Files Locations
- **LUKS Header Backup**: ________________
- **Challenge Backup**: ________________
- **Recovery Notes**: ________________

## 🔐 GPG Configuration

### Master Key Information
- **Key ID**: ________________
- **Key Fingerprint**: ________________
- **Creation Date**: ________________
- **Expiration Date**: ________________
- **Algorithm**: ________________ (typically RSA4096)

### Subkeys on YubiKey
- **Signing Subkey ID**: ________________
- **Encryption Subkey ID**: ________________
- **Authentication Subkey ID**: ________________

### Backup Locations
- **Master Secret Key**: ________________ (OFFLINE ONLY!)
- **Secret Subkeys**: ________________
- **Public Key**: ________________
- **Revocation Certificate**: ________________
- **SSH Public Key from GPG**: ________________

## 📱 OATH/TOTP Accounts

### Account 1
- **Service Name**: ________________
- **Account/Username**: ________________
- **Touch Required**: ☐ Yes ☐ No
- **Secret Backup Location**: ________________
- **QR Code Backup**: ☐ Stored ☐ Printed
- **Service Backup Codes**: ________________

### Account 2
- **Service Name**: ________________
- **Account/Username**: ________________
- **Touch Required**: ☐ Yes ☐ No
- **Secret Backup Location**: ________________
- **QR Code Backup**: ☐ Stored ☐ Printed
- **Service Backup Codes**: ________________

### Account 3
- **Service Name**: ________________
- **Account/Username**: ________________
- **Touch Required**: ☐ Yes ☐ No
- **Secret Backup Location**: ________________
- **QR Code Backup**: ☐ Stored ☐ Printed
- **Service Backup Codes**: ________________

### Account 4
- **Service Name**: ________________
- **Account/Username**: ________________
- **Touch Required**: ☐ Yes ☐ No
- **Secret Backup Location**: ________________
- **QR Code Backup**: ☐ Stored ☐ Printed
- **Service Backup Codes**: ________________

### Account 5
- **Service Name**: ________________
- **Account/Username**: ________________
- **Touch Required**: ☐ Yes ☐ No
- **Secret Backup Location**: ________________
- **QR Code Backup**: ☐ Stored ☐ Printed
- **Service Backup Codes**: ________________

*Add more sections as needed...*

## 🌐 U2F/WebAuthn Registrations

### PAM U2F (Linux Login)
- **Registration File**: ________________
- **Backup Location**: ________________

### Website Registrations
- **GitHub**: ☐ Registered - Backup codes: ________________
- **Google**: ☐ Registered - Backup codes: ________________
- **Microsoft**: ☐ Registered - Backup codes: ________________
- **Bitwarden**: ☐ Registered - Backup codes: ________________
- **Other**: ________________ - Backup codes: ________________

## 💼 Backup Strategy

### Primary Backups (Encrypted)
- **Location 1**: ________________
- **Contents**: ________________
- **Last Updated**: ________________

### Secondary Backups (Offline)
- **Location 2**: ________________
- **Contents**: ________________
- **Last Updated**: ________________

### Emergency Access
- **Backup YubiKey**: ☐ Configured ☐ Not configured
- **Backup YubiKey Location**: ________________
- **Emergency Contact**: ________________
- **Recovery Documentation**: ________________

## 🚨 Emergency Procedures

### If YubiKey is Lost/Stolen
1. ☐ Immediately disable YubiKey access from all services
2. ☐ Use backup YubiKey if available
3. ☐ Generate new keys from backups
4. ☐ Update all service registrations
5. ☐ Check access logs for unauthorized use

### If PIN/Password is Forgotten
1. ☐ Use PUK to reset PIN (for PIV)
2. ☐ Check this document for recorded PINs
3. ☐ Factory reset as last resort (loses all data)
4. ☐ Restore from backups

### Service Contact Information
- **Support Contact 1**: ________________
- **Support Contact 2**: ________________
- **IT Department**: ________________

## 📝 Setup Commands Reference

### Backup Commands Used
```bash
# OATH backup command used:
ykman oath accounts uri "SERVICE:USERNAME" > backup-file.txt

# GPG backup commands used:
gpg --export-secret-keys --armor KEY_ID > master-secret-key.asc

# SSH key backup:
cp ~/.ssh/id_ed25519_sk.pub ~/secure-backup/
