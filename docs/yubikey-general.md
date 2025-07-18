# Complete YubiKey Setup Guide for NixOS

⚠️ **This document is quite comprehensive (1600+ lines). For quicker setup:**
- 🚀 **Quick start**: See [YubiKey Quick Setup](yubikey-quick-setup.md) (30 minutes)
- 📋 **Planning**: See [Pre-deployment Checklist](yubikey-checklist.md) 
- 📚 **Overview**: See [YubiKey Overview](yubikey-overview.md) for guided approach

**This document contains the complete reference for all YubiKey security features.**

This comprehensive guide covers setting up a YubiKey from scratch for multiple security applications including LUKS disk encryption, SSH authentication, user login, 2FA, GPG signing/encryption, and other useful security features.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Initial YubiKey Setup](#initial-yubikey-setup)
3. [LUKS Disk Encryption](#luks-disk-encryption)
4. [SSH Authentication](#ssh-authentication)
5. [User Login (PAM)](#user-login-pam)
6. [2FA/TOTP Setup](#2fatotp-setup)
7. [GPG Keys](#gpg-keys)
8. [Additional Applications](#additional-applications)
9. [🔒 Critical Backup Requirements](#-critical-backup-requirements)
10. [🗑️ Security Cleanup Checklist](#️-security-cleanup-checklist)
11. [Security Best Practices](#security-best-practices)
12. [Troubleshooting](#troubleshooting)

## Prerequisites

### Hardware Requirements
- **YubiKey 4/5 series** (recommended for full feature support)
- **USB-A or USB-C** depending on your devices
- **NFC support** (optional, for mobile use)

### Software Requirements
```bash
# Install required packages on NixOS
nix-shell -p yubikey-manager yubikey-personalization libfido2 gnupg pinentry-gtk2 pam_u2f cryptsetup
```

### Check YubiKey Detection
```bash
# Verify YubiKey is detected
lsusb | grep Yubico
ykman info
```

## Initial YubiKey Setup

🔧 **PRE-CONFIGURATION**: These steps can be done in advance in a secure location

### 1. Factory Reset (if needed)

### 1. Factory Reset (if needed)
🔧 **PRE-CONFIGURATION**: Can be done in advance

```bash
# WARNING: This will erase ALL data on the YubiKey!
ykman config usb --disable-all
ykman config usb --enable-all
ykman piv reset  # Reset PIV application
ykman oath reset # Reset OATH application
ykman openpgp reset # Reset OpenPGP application
```

### 2. Enable Required Interfaces
🔧 **PRE-CONFIGURATION**: Can be done in advance

📝 **BACKUP**: Configuration in Bitwarden note
- Interface settings → Bitwarden note for reference
- YubiKey model and serial → Bitwarden note

```bash
# Enable all interfaces you'll need
ykman config usb --enable-all
ykman config nfc --enable-all  # If you have NFC model

# 📝 BACKUP: Record current configuration
ykman info > yubikey-config.txt
```

### 3. Set Device Info
🔧 **PRE-CONFIGURATION**: Can be done in advance

📝 **BACKUP**: Lock code in Bitwarden secure note
- Configuration lock code → Bitwarden secure note (if set)

```bash
# Optional: Set device info for identification
ykman config set-lock-code  # Set a configuration lock code
```

## LUKS Disk Encryption

### Overview
Use YubiKey challenge-response for LUKS unlock, allowing disk decryption without typing a password.

### 1. Configure Challenge-Response Slot
🔧 **PRE-CONFIGURATION**: Must be done in advance

📝 **BACKUP**: Record slot configuration in Bitwarden note
- Note: "YubiKey slot 2 = HMAC-SHA1 challenge-response for LUKS"
- Include YubiKey serial number for reference

```bash
# Configure slot 2 for HMAC-SHA1 challenge-response
# Slot 1 is typically reserved for Yubico OTP
ykman otp chalresp --generate 2

# Verify configuration
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"
```

### 2. Add YubiKey to Existing LUKS
⚠️ **ON-SITE DEPLOYMENT**: Must be done with actual encrypted disk

🔒 **BACKUP**: Critical files requiring secure storage
- `luks-header-backup.img` → Encrypted external drive (NOT Bitwarden)
- `luks-uuid.txt` → Bitwarden note
- Challenge string used → Bitwarden note

```bash
# For existing LUKS partition
LUKS_DEVICE="/dev/nvme0n1p2"  # Adjust to your encrypted partition

# 🔒 BACKUP: Create LUKS header backup FIRST
sudo cryptsetup luksHeaderBackup "$LUKS_DEVICE" --header-backup-file luks-header-backup.img

# 🔒 BACKUP: Record LUKS UUID
sudo cryptsetup luksDump "$LUKS_DEVICE" | grep UUID > luks-uuid.txt

# Create challenge and response
CHALLENGE="luks-unlock-$(date +%s)"
RESPONSE=$(ykman otp calculate 2 "$(echo -n "$CHALLENGE" | xxd -p)")

# 🔒 BACKUP: Record the challenge string used
echo "Challenge used: $CHALLENGE" >> yubikey-luks-challenge.txt

# Convert response to binary key
echo -n "$RESPONSE" | xxd -r -p > /tmp/yk-luks-key

# Add YubiKey key to LUKS (you'll need existing passphrase)
sudo cryptsetup luksAddKey "$LUKS_DEVICE" /tmp/yk-luks-key

# Securely delete temporary key
shred -vfz /tmp/yk-luks-key
```

### 3. NixOS Configuration
🔧 **PRE-CONFIGURATION**: Can be prepared in advance

Add to your NixOS configuration:

```nix
# In your host configuration
{
  # Enable YubiKey support in initrd
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/your-luks-uuid";
    yubikey = {
      slot = 2;
      twoFactor = true;  # Require both YubiKey AND password
      gracePeriod = 2;   # Seconds to wait for YubiKey
      keyLength = 64;    # Key length in characters
      saltLength = 16;   # Salt length
    };
  };
  
  # Required packages
  environment.systemPackages = with pkgs; [
    yubikey-manager
    cryptsetup
  ];
}
```

## SSH Authentication

### Overview
Use YubiKey as an SSH key store via PIV (PKCS#11) or FIDO2/WebAuthn.

### Method 1: PIV/PKCS#11 (Traditional)

#### 1. Generate SSH Key on YubiKey
🔧 **PRE-CONFIGURATION**: Can be done in advance

📝 **BACKUP**: PINs and public key in Bitwarden notes
- PIV PIN (changed from default) → Bitwarden secure note
- PIV PUK (changed from default) → Bitwarden secure note  
- SSH public key → Bitwarden note (safe to store)

```bash
# Set PIV PIN (default is 123456)
ykman piv access change-pin

# Set PIV PUK (default is 12345678) 
ykman piv access change-puk

# Generate RSA key in slot 9a (authentication)
ykman piv keys generate --algorithm RSA2048 9a /tmp/pubkey.pem

# Create self-signed certificate
ykman piv certificates generate --subject "CN=SSH Key" 9a /tmp/pubkey.pem

# Extract SSH public key
ssh-keygen -D /usr/lib/x86_64-linux-gnu/libykcs11.so -e > ~/.ssh/id_rsa_yubikey.pub

# 📝 BACKUP: Save public key to Bitwarden note
cat ~/.ssh/id_rsa_yubikey.pub
```

#### 2. SSH Client Configuration
🔧 **PRE-CONFIGURATION**: Can be done in advance

```bash
# Add to ~/.ssh/config
cat >> ~/.ssh/config << EOF
Host *
    PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
EOF
```

#### 3. Deploy to Servers
⚠️ **ON-SITE DEPLOYMENT**: Must be done for each target server

```bash
# Copy public key to servers
ssh-copy-id -i ~/.ssh/id_rsa_yubikey.pub user@server
```

### Method 2: FIDO2/WebAuthn (Modern, Recommended)

#### 1. Generate FIDO2 SSH Key
🔧 **PRE-CONFIGURATION**: Can be done in advance

📝 **BACKUP**: Public key in Bitwarden notes
- SSH public key → Bitwarden note (safe to store)
- Key type and options used → Bitwarden note for reference

```bash
# Generate FIDO2 SSH key (requires touch)
ssh-keygen -t ed25519-sk -O resident -O verify-required -f ~/.ssh/id_ed25519_sk

# Or generate without resident key (stored locally)
ssh-keygen -t ed25519-sk -O verify-required -f ~/.ssh/id_ed25519_sk

# 📝 BACKUP: Save public key to Bitwarden note
cat ~/.ssh/id_ed25519_sk.pub
```

#### 2. Add Public Key to Servers
⚠️ **ON-SITE DEPLOYMENT**: Must be done for each target server

```bash
# Copy public key to servers
ssh-copy-id -i ~/.ssh/id_ed25519_sk.pub user@server
```

#### 3. NixOS SSH Server Configuration
🔧 **PRE-CONFIGURATION**: Can be prepared in advance

```nix
# Enable FIDO2 support in SSH server
services.openssh = {
  enable = true;
  settings = {
    PubkeyAuthentication = true;
    AuthenticationMethods = "publickey";
  };
};
```

## User Login (PAM)

### Overview
Use YubiKey for local user authentication via PAM U2F module.

### 1. Setup U2F for PAM
⚠️ **ON-SITE DEPLOYMENT**: Must be done on target system

🔒 **BACKUP**: U2F registration files requiring secure storage
- `u2f_keys` file → Encrypted external drive (NOT Bitwarden - contains private tokens)
- Instructions for re-registration → Bitwarden note

```bash
# Create U2F directory
mkdir -p ~/.config/Yubico

# Register YubiKey for U2F (requires touch)
pamu2fcfg > ~/.config/Yubico/u2f_keys

# For system-wide (requires root)
sudo mkdir -p /etc/Yubico
sudo pamu2fcfg -u$(whoami) | sudo tee /etc/Yubico/u2f_keys

# 🔒 BACKUP: Copy u2f_keys file to secure storage
cp ~/.config/Yubico/u2f_keys ~/secure-backup/u2f_keys-$(hostname)
```

### 2. NixOS PAM Configuration
🔧 **PRE-CONFIGURATION**: Can be prepared in advance

```nix
# Add to your NixOS configuration
{
  # Enable U2F support
  security.pam.u2f = {
    enable = true;
    settings = {
      cue = true;           # Show "touch YubiKey" message
      interactive = true;    # Allow fallback to password
      authFile = "/etc/Yubico/u2f_keys";
    };
  };

  # Configure PAM services
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    polkit-1.u2fAuth = true;
    # Add other services as needed
  };

  # Required packages
  environment.systemPackages = with pkgs; [
    pam_u2f
    libfido2
  ];
}
```

### 3. Test U2F Login
⚠️ **ON-SITE DEPLOYMENT**: Must be tested on target system

```bash
# Test sudo with U2F
sudo echo "Testing U2F authentication"
# You should see "Please touch the device" and need to touch YubiKey
```

## 2FA/TOTP Setup

### Overview
Use YubiKey as a TOTP authenticator for websites and services.

### 1. Add TOTP Accounts
🔧 **PRE-CONFIGURATION**: Can be done in advance (if you have secret keys)

🔒 **BACKUP**: TOTP secrets requiring secure storage
- OATH account URIs → Encrypted external drive (NOT Bitwarden - contains secret keys)
- QR codes (printed) → Physical safe or safety deposit box
- Service backup codes → Bitwarden secure notes (separate from OATH secrets)

```bash
# Add account manually (you'll need the secret key)
ykman oath accounts add "GitHub:username" JBSWY3DPEHPK3PXP

# Add account via QR code (if you have camera/scanner)
ykman oath accounts add "Service:username" --issuer "Service Name"

# Add account with touch requirement for extra security
ykman oath accounts add --touch "Banking:username" SECRET_KEY

# 🔒 BACKUP: Export account URIs for recovery
ykman oath accounts uri "GitHub:username" > github-oath-backup.txt
ykman oath accounts uri "Banking:username" > banking-oath-backup.txt

# 🔒 BACKUP: Generate QR codes for manual recovery
ykman oath accounts uri --qr "GitHub:username" > github-qr.png
```

### 2. Generate TOTP Codes
🔧 **PRE-CONFIGURATION**: Works anywhere after setup

```bash
# List all accounts
ykman oath accounts list

# Generate code for specific account
ykman oath accounts code "GitHub:username"

# Generate all codes
ykman oath accounts code

# Generate code with touch requirement
ykman oath accounts code "Banking:username"  # Will require touch
```

### 3. Service Registration
⚠️ **ON-SITE DEPLOYMENT**: Must be done for each service account

```bash
# Register with each service during account setup
# 1. Service → Security Settings → Enable 2FA
# 2. Choose "Authenticator App" 
# 3. Use ykman oath accounts code to get current code
# 4. Enter code to verify setup
```

### 4. Backup TOTP Secrets
🔧 **PRE-CONFIGURATION**: Can be done in advance

🔒 **BACKUP**: Critical TOTP recovery data
- OATH URIs with secret keys → Encrypted external drive (NOT Bitwarden)
- Printed QR codes → Physical safe
- Service names and usernames → Bitwarden note (safe without secrets)

```bash
# Export accounts (keep this secure!)
ykman oath accounts uri "GitHub:username" > github-backup.txt

# Print QR code for manual backup
ykman oath accounts uri --qr "GitHub:username"

# 🔒 BACKUP: Create comprehensive backup
for account in $(ykman oath accounts list); do
    echo "=== $account ===" >> oath-complete-backup.txt
    ykman oath accounts uri "$account" >> oath-complete-backup.txt
    echo "" >> oath-complete-backup.txt
done
```

## GPG Keys

### Overview
Store GPG keys on YubiKey for signing, encryption, and authentication.

### 1. Generate Master Key (Offline)
🔧 **PRE-CONFIGURATION**: Should be done in secure offline environment

🔒 **BACKUP**: Most critical backup - multiple secure locations required
- Master secret key → Encrypted offline storage + physical safe (NEVER online)
- Master public key → Bitwarden note (safe to store)
- Key fingerprint → Bitwarden note
- Revocation certificate → Separate secure location from master key

```bash
# Generate master key offline (air-gapped system recommended)
gpg --expert --full-gen-key

# Choose:
# (1) RSA and RSA (default)
# 4096 bit key size
# Key does not expire (or set expiration)
# Enter your name and email

# 🔒 BACKUP: Export master secret key (OFFLINE STORAGE ONLY!)
gpg --export-secret-keys --armor YOUR_KEY_ID > master-secret-key.asc

# 📝 BACKUP: Export public key (safe for Bitwarden)
gpg --export --armor YOUR_KEY_ID > public-key.asc

# 🔒 BACKUP: Generate revocation certificate
gpg --gen-revoke YOUR_KEY_ID > revocation-certificate.asc

# 📝 BACKUP: Record key fingerprint in Bitwarden
gpg --fingerprint YOUR_KEY_ID
```

### 2. Generate Subkeys
🔧 **PRE-CONFIGURATION**: Can be done in advance

🔒 **BACKUP**: Subkey backup for YubiKey recovery
- Secret subkeys → Encrypted external drive (for YubiKey replacement)
- Subkey fingerprints → Bitwarden note

```bash
# Edit the key to add subkeys
gpg --expert --edit-key YOUR_KEY_ID

# In GPG prompt:
gpg> addkey
# Choose encryption subkey: (6) RSA (encrypt only)
gpg> addkey  
# Choose authentication subkey: (8) RSA (set your own capabilities)
# Toggle capabilities to only 'Authenticate'
gpg> save

# 🔒 BACKUP: Export secret subkeys (for YubiKey replacement scenarios)
gpg --export-secret-subkeys --armor YOUR_KEY_ID > secret-subkeys.asc

# 📝 BACKUP: Record subkey fingerprints
gpg --list-keys --with-subkey-fingerprints YOUR_KEY_ID
```

### 3. Transfer Keys to YubiKey
🔧 **PRE-CONFIGURATION**: Can be done in advance

```bash
# Edit key for transfer
gpg --edit-key YOUR_KEY_ID

# Move signing subkey
gpg> key 1
gpg> keytocard
# Choose (1) Signature key

# Move encryption subkey  
gpg> key 2
gpg> keytocard
# Choose (2) Encryption key

# Move authentication subkey
gpg> key 3
gpg> keytocard
# Choose (3) Authentication key

gpg> save
```

### 4. Configure GPG for YubiKey
🔧 **PRE-CONFIGURATION**: Can be prepared in advance

```bash
# Add to ~/.gnupg/gpg-agent.conf
cat >> ~/.gnupg/gpg-agent.conf << EOF
enable-ssh-support
pinentry-program /run/current-system/sw/bin/pinentry-gtk2
default-cache-ttl 60
max-cache-ttl 120
EOF

# Add to ~/.gnupg/scdaemon.conf
cat >> ~/.gnupg/scdaemon.conf << EOF
reader-port Yubico YubiKey
card-timeout 5
disable-ccid
EOF

# Restart GPG agent
gpgconf --kill gpg-agent
```

### 5. NixOS GPG Configuration
🔧 **PRE-CONFIGURATION**: Can be prepared in advance

```nix
# Add to your NixOS configuration
{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-gtk2
    yubikey-manager
  ];

  # Set environment variables
  environment.sessionVariables = {
    GPG_TTY = "$(tty)";
    SSH_AUTH_SOCK = "/run/user/1000/gnupg/S.gpg-agent.ssh";
  };
}
```

### 6. Export Public Keys
🔧 **PRE-CONFIGURATION**: Can be done in advance

📝 **BACKUP**: Public keys and SSH key in Bitwarden notes
- GPG public key → Bitwarden note (safe to store)
- SSH public key from GPG → Bitwarden note (safe to store)
- Keyserver upload confirmation → Bitwarden note

```bash
# Export public key for sharing
gpg --export --armor YOUR_KEY_ID > public-key.asc

# Upload to keyserver
gpg --send-keys YOUR_KEY_ID

# Export SSH public key from GPG
gpg --export-ssh-key YOUR_KEY_ID > ~/.ssh/id_rsa_yubikey.pub

# 📝 BACKUP: Save to Bitwarden notes
cat public-key.asc
cat ~/.ssh/id_rsa_yubikey.pub
```

## Additional Applications

### 1. WebAuthn/FIDO2 for Websites
⚠️ **ON-SITE DEPLOYMENT**: Must be done for each service account

Most modern websites support FIDO2/WebAuthn:
- **GitHub**: Settings → Security → Security keys
- **Google**: myaccount.google.com → Security → 2-Step Verification
- **Microsoft**: account.microsoft.com → Security → Security key
- **Twitter/X**: Settings → Security → Two-factor authentication

### 2. Password Manager Integration
🔧 **PRE-CONFIGURATION**: YubiKey setup can be done in advance
⚠️ **ON-SITE DEPLOYMENT**: Service registration must be done with accounts

YubiKey works with many password managers:
- **Bitwarden**: Premium feature (FIDO2/WebAuthn recommended)
- **1Password**: Business/Family plans
- **KeePassXC**: Native support via challenge-response

### 3. Code Signing
🔧 **PRE-CONFIGURATION**: Can be prepared in advance

```bash
# Sign Git commits with YubiKey GPG key
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
git config --global gpg.program gpg
```

### 4. Email Encryption
🔧 **PRE-CONFIGURATION**: Can be prepared in advance

```bash
# Configure email client (Thunderbird, Evolution, etc.)
# Import your public GPG key
# Configure to use YubiKey for decryption/signing
```

### 2. Enable Required Interfaces
```bash
# Enable all interfaces you'll need
ykman config usb --enable-all
ykman config nfc --enable-all  # If you have NFC model
```

### 3. Set Device Info
```bash
# Optional: Set device info for identification
ykman config set-lock-code  # Set a configuration lock code
```

## LUKS Disk Encryption

### Overview
Use YubiKey challenge-response for LUKS unlock, allowing disk decryption without typing a password.

### 1. Configure Challenge-Response Slot
```bash
# Configure slot 2 for HMAC-SHA1 challenge-response
# Slot 1 is typically reserved for Yubico OTP
ykman otp chalresp --generate 2

# Verify configuration
ykman otp calculate 2 "$(echo -n 'test' | xxd -p)"
```

### 2. Add YubiKey to Existing LUKS
```bash
# For existing LUKS partition
LUKS_DEVICE="/dev/nvme0n1p2"  # Adjust to your encrypted partition

# Create challenge and response
CHALLENGE="luks-unlock-$(date +%s)"
RESPONSE=$(ykman otp calculate 2 "$(echo -n "$CHALLENGE" | xxd -p)")

# Convert response to binary key
echo -n "$RESPONSE" | xxd -r -p > /tmp/yk-luks-key

# Add YubiKey key to LUKS (you'll need existing passphrase)
sudo cryptsetup luksAddKey "$LUKS_DEVICE" /tmp/yk-luks-key

# Securely delete temporary key
shred -vfz /tmp/yk-luks-key
```

### 3. NixOS Configuration
Add to your NixOS configuration:

```nix
# In your host configuration
{
  # Enable YubiKey support in initrd
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/your-luks-uuid";
    yubikey = {
      slot = 2;
      twoFactor = true;  # Require both YubiKey AND password
      gracePeriod = 2;   # Seconds to wait for YubiKey
      keyLength = 64;    # Key length in characters
      saltLength = 16;   # Salt length
    };
  };
  
  # Required packages
  environment.systemPackages = with pkgs; [
    yubikey-manager
    cryptsetup
  ];
}
```

## SSH Authentication

### Overview
Use YubiKey as an SSH key store via PIV (PKCS#11) or FIDO2/WebAuthn.

### Method 1: PIV/PKCS#11 (Traditional)

#### 1. Generate SSH Key on YubiKey
```bash
# Set PIV PIN (default is 123456)
ykman piv access change-pin

# Set PIV PUK (default is 12345678) 
ykman piv access change-puk

# Generate RSA key in slot 9a (authentication)
ykman piv keys generate --algorithm RSA2048 9a /tmp/pubkey.pem

# Create self-signed certificate
ykman piv certificates generate --subject "CN=SSH Key" 9a /tmp/pubkey.pem

# Extract SSH public key
ssh-keygen -D /usr/lib/x86_64-linux-gnu/libykcs11.so -e
```

#### 2. SSH Client Configuration
```bash
# Add to ~/.ssh/config
cat >> ~/.ssh/config << EOF
Host *
    PKCS11Provider /usr/lib/x86_64-linux-gnu/libykcs11.so
EOF
```

### Method 2: FIDO2/WebAuthn (Modern, Recommended)

#### 1. Generate FIDO2 SSH Key
```bash
# Generate FIDO2 SSH key (requires touch)
ssh-keygen -t ed25519-sk -O resident -O verify-required -f ~/.ssh/id_ed25519_sk

# Or generate without resident key (stored locally)
ssh-keygen -t ed25519-sk -O verify-required -f ~/.ssh/id_ed25519_sk
```

#### 2. Add Public Key to Servers
```bash
# Copy public key to servers
ssh-copy-id -i ~/.ssh/id_ed25519_sk.pub user@server
```

#### 3. NixOS SSH Server Configuration
```nix
# Enable FIDO2 support in SSH server
services.openssh = {
  enable = true;
  settings = {
    PubkeyAuthentication = true;
    AuthenticationMethods = "publickey";
  };
};
```

## User Login (PAM)

### Overview
Use YubiKey for local user authentication via PAM U2F module.

### 1. Setup U2F for PAM
```bash
# Create U2F directory
mkdir -p ~/.config/Yubico

# Register YubiKey for U2F (requires touch)
pamu2fcfg > ~/.config/Yubico/u2f_keys

# For system-wide (requires root)
sudo mkdir -p /etc/Yubico
sudo pamu2fcfg -u$(whoami) | sudo tee /etc/Yubico/u2f_keys
```

### 2. NixOS PAM Configuration
```nix
# Add to your NixOS configuration
{
  # Enable U2F support
  security.pam.u2f = {
    enable = true;
    settings = {
      cue = true;           # Show "touch YubiKey" message
      interactive = true;    # Allow fallback to password
      authFile = "/etc/Yubico/u2f_keys";
    };
  };

  # Configure PAM services
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    polkit-1.u2fAuth = true;
    # Add other services as needed
  };

  # Required packages
  environment.systemPackages = with pkgs; [
    pam_u2f
    libfido2
  ];
}
```

### 3. Test U2F Login
```bash
# Test sudo with U2F
sudo echo "Testing U2F authentication"
# You should see "Please touch the device" and need to touch YubiKey
```

## 2FA/TOTP Setup

### Overview
Use YubiKey as a TOTP authenticator for websites and services.

### 1. Add TOTP Accounts
```bash
# Add account manually (you'll need the secret key)
ykman oath accounts add "GitHub:username" JBSWY3DPEHPK3PXP

# Add account via QR code (if you have camera/scanner)
ykman oath accounts add "Service:username" --issuer "Service Name"

# Add account with touch requirement for extra security
ykman oath accounts add --touch "Banking:username" SECRET_KEY
```

### 2. Generate TOTP Codes
```bash
# List all accounts
ykman oath accounts list

# Generate code for specific account
ykman oath accounts code "GitHub:username"

# Generate all codes
ykman oath accounts code

# Generate code with touch requirement
ykman oath accounts code "Banking:username"  # Will require touch
```

### 3. Backup TOTP Secrets
```bash
# Export accounts (keep this secure!)
ykman oath accounts uri "GitHub:username" > github-backup.txt

# Print QR code for manual backup
ykman oath accounts uri --qr "GitHub:username"
```

## GPG Keys

### Overview
Store GPG keys on YubiKey for signing, encryption, and authentication.

### 1. Generate Master Key (Offline)
```bash
# Generate master key offline (air-gapped system recommended)
gpg --expert --full-gen-key

# Choose:
# (1) RSA and RSA (default)
# 4096 bit key size
# Key does not expire (or set expiration)
# Enter your name and email
```

### 2. Generate Subkeys
```bash
# Edit the key to add subkeys
gpg --expert --edit-key YOUR_KEY_ID

# In GPG prompt:
gpg> addkey
# Choose encryption subkey: (6) RSA (encrypt only)
gpg> addkey  
# Choose authentication subkey: (8) RSA (set your own capabilities)
# Toggle capabilities to only 'Authenticate'
gpg> save
```

### 3. Transfer Keys to YubiKey
```bash
# Edit key for transfer
gpg --edit-key YOUR_KEY_ID

# Move signing subkey
gpg> key 1
gpg> keytocard
# Choose (1) Signature key

# Move encryption subkey  
gpg> key 2
gpg> keytocard
# Choose (2) Encryption key

# Move authentication subkey
gpg> key 3
gpg> keytocardykman info
ykman otp
# Choose (3) Authentication key

gpg> save
```

### 4. Configure GPG for YubiKey
```bash
# Add to ~/.gnupg/gpg-agent.conf
cat >> ~/.gnupg/gpg-agent.conf << EOF
enable-ssh-support
pinentry-program /run/current-system/sw/bin/pinentry-gtk2
default-cache-ttl 60
max-cache-ttl 120
EOF

# Add to ~/.gnupg/scdaemon.conf
cat >> ~/.gnupg/scdaemon.conf << EOF
reader-port Yubico YubiKey
card-timeout 5
disable-ccid
EOF

# Restart GPG agent
gpgconf --kill gpg-agent
```

### 5. NixOS GPG Configuration
```nix
# Add to your NixOS configuration
{
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };

  environment.systemPackages = with pkgs; [
    gnupg
    pinentry-gtk2
    yubikey-manager
  ];

  # Set environment variables
  environment.sessionVariables = {
    GPG_TTY = "$(tty)";
    SSH_AUTH_SOCK = "/run/user/1000/gnupg/S.gpg-agent.ssh";
  };
}
```

### 6. Export Public Keys
```bash
# Export public key for sharing
gpg --export --armor YOUR_KEY_ID > public-key.asc

# Upload to keyserver
gpg --send-keys YOUR_KEY_ID

# Export SSH public key from GPG
gpg --export-ssh-key YOUR_KEY_ID > ~/.ssh/id_rsa_yubikey.pub
```

## Additional Applications

### 1. WebAuthn/FIDO2 for Websites
Most modern websites support FIDO2/WebAuthn:
- **GitHub**: Settings → Security → Security keys
- **Google**: myaccount.google.com → Security → 2-Step Verification
- **Microsoft**: account.microsoft.com → Security → Security key
- **Twitter/X**: Settings → Security → Two-factor authentication

### 2. Password Manager Integration
YubiKey works with many password managers:
- **Bitwarden**: Premium feature (FIDO2/WebAuthn recommended)
- **1Password**: Business/Family plans
- **KeePassXC**: Native support via challenge-response

### 3. Code Signing
```bash
# Sign Git commits with YubiKey GPG key
git config --global user.signingkey YOUR_KEY_ID
git config --global commit.gpgsign true
git config --global gpg.program gpg
```

### 4. Email Encryption
```bash
# Configure email client (Thunderbird, Evolution, etc.)
# Import your public GPG key
# Configure to use YubiKey for decryption/signing
```

## 🔒 Critical Backup Requirements

⚠️ **THESE ITEMS MUST BE SECURELY BACKED UP BEFORE PROCEEDING** ⚠️

### 🔒 **ENCRYPTED EXTERNAL DRIVE** (Never store online)
**Critical files that must be kept offline:**

1. **GPG Master Secret Key** (`master-secret-key.asc`)
   - Most critical backup - store in multiple secure locations
   - Never upload to cloud or store on networked systems
   - Consider paper backup for ultimate security

2. **GPG Secret Subkeys** (`secret-subkeys.asc`)
   - Needed for YubiKey replacement scenarios
   - Store separately from master key if possible

3. **LUKS Header Backup** (`luks-header-backup.img`)
   - Essential for disk recovery if disk corruption occurs
   - Test recovery procedure before relying on it

4. **OATH/TOTP Secrets** (`oath-complete-backup.txt`)
   - Contains secret keys for 2FA accounts
   - Extremely sensitive - never store in password managers

5. **U2F Registration Files** (`u2f_keys`)
   - System-specific authentication tokens
   - Cannot be regenerated - only re-registered

6. **GPG Revocation Certificate** (`revocation-certificate.asc`)
   - Store in separate location from master key
   - Only way to revoke key if master key is lost

### 📝 **BITWARDEN SECURE NOTES** (Safe to store)
**Information that doesn't contain secrets:**

1. **YubiKey Configuration**
   - Serial numbers, slot configurations
   - Interface settings (USB/NFC)
   - PIN/PUK change dates

2. **Public Keys and Fingerprints**
   - GPG public key (armor format)
   - SSH public keys (all methods)
   - GPG key fingerprints and IDs

3. **System Configuration References**
   - LUKS UUIDs and device paths
   - Challenge strings used (without responses)
   - NixOS configuration snippets

4. **Service Account Information**
   - 2FA service names and usernames (without secrets)
   - SSH server configurations
   - Recovery instructions

5. **Backup Procedures**
   - Recovery step-by-step instructions
   - Emergency contact information
   - Location references for secure storage

### 🏦 **PHYSICAL SAFE / SAFETY DEPOSIT BOX**
**Offline paper backups:**

1. **Printed QR Codes**
   - OATH/TOTP QR codes for manual entry
   - GPG key QR codes (if generated)
   - Emergency recovery codes from services

2. **Written Information**
   - Master key passphrase (if not memorized)
   - Critical PINs and passwords
   - Location information for digital backups

3. **Hardware Backup**
   - Second YubiKey with identical configuration
   - Hardware security modules (if used)

### ⚠️ **BACKUP SECURITY RULES**

#### **NEVER Store in Bitwarden:**
- GPG secret/private keys
- OATH/TOTP secret keys or URIs
- LUKS encryption keys or headers
- U2F private registration data
- Any file containing cryptographic secrets

#### **ALWAYS Store in Bitwarden:**
- Public keys (safe to share)
- Service usernames and account info
- Configuration references and UUIDs
- Recovery procedures and instructions
- Non-secret system information

#### **Multiple Location Strategy:**
- **Primary**: Encrypted external drive (main backup)
- **Secondary**: Different physical location (redundancy)
- **Tertiary**: Paper backup in safe (ultimate fallback)
- **Reference**: Bitwarden notes (convenience + non-secrets)

### 🔍 **Backup Verification Checklist**

Before relying on your YubiKey setup:

- [ ] **GPG master key** backed up to offline storage
- [ ] **GPG revocation certificate** in separate secure location
- [ ] **LUKS header backup** tested for restoration
- [ ] **OATH accounts** exported and QR codes printed
- [ ] **SSH public keys** saved to Bitwarden notes
- [ ] **U2F registration files** copied to secure storage
- [ ] **Recovery procedures** documented and tested
- [ ] **Second YubiKey** configured identically (if available)
- [ ] **Physical access** to all backup locations verified
- [ ] **Test recovery** performed on non-production system

### 🔐 **Age/SOPS for YubiKey Backups**

Age and SOPS can be safely used for **some** YubiKey-related backups, but with important considerations:

#### **✅ SAFE to encrypt with Age/SOPS:**

**1. Configuration and Reference Data**
```bash
# Safe: System configuration files
age -e -R ~/.config/age/recipients.txt < yubikey-config.txt > yubikey-config.age
sops -e yubikey-setup-notes.yaml

# Safe: Public keys and non-secret references
age -e -R ~/.config/age/recipients.txt < ssh-public-keys.txt > ssh-keys.age
```

**2. LUKS Setup Information (Non-Critical Parts)**
```bash
# Safe: LUKS UUIDs, device paths, challenge strings (not responses)
echo "LUKS_UUID=$(blkid -s UUID -o value /dev/nvme0n1p2)" | age -e -R recipients.txt > luks-info.age

# Safe: NixOS configuration snippets
sops -e luks-nixos-config.yaml
```

**3. Service Account Information**
```bash
# Safe: Username/service mappings without secrets
sops -e service-accounts.yaml  # Contains usernames, not passwords
```

#### **⚠️ USE WITH EXTREME CAUTION:**

**1. OATH/TOTP Secrets** (High-risk circular dependency)
```bash
# RISKY: If you use YubiKey PIV for age/sops, this creates circular dependency
# If YubiKey is lost, you can't decrypt OATH backups to reconfigure new YubiKey

# Safer approach: Use separate age identity not dependent on YubiKey
age-keygen > ~/.config/age/backup-identity.txt  # Store this separately!
age -e -i ~/.config/age/backup-identity.txt < oath-secrets.txt > oath-backup.age
```

**2. GPG Secret Subkeys** (For YubiKey replacement only)
```bash
# CAUTION: Only if using non-YubiKey age identity
age -e -i ~/.config/age/backup-identity.txt < secret-subkeys.asc > subkeys.age
```

#### **❌ NEVER encrypt with Age/SOPS:**

**1. GPG Master Secret Key**
- Too critical for any automated system
- Risk of circular dependency
- Should always have offline-only backups

**2. Age/SOPS Identity Keys Themselves**
- Creates impossible circular dependency
- Store identity keys on separate secure media

**3. LUKS Header Backups**
- Critical for system recovery
- Should have offline copy accessible without decryption tools

#### **🔄 Circular Dependency Risks**

**The Problem:**
```bash
# DANGEROUS: YubiKey PIV -> Age/SOPS -> OATH secrets -> YubiKey recovery
# If YubiKey is lost: Can't decrypt Age/SOPS -> Can't get OATH -> Can't setup new YubiKey
```

**Safe Solutions:**

**Option 1: Separate Age Identity**
```bash
# Create dedicated backup identity (store securely offline)
age-keygen > ~/.config/age/emergency-identity.txt

# Use for critical backups
age -e -i ~/.config/age/emergency-identity.txt < critical-data.txt > backup.age

# Store emergency-identity.txt on separate secure media
```

**Option 2: Multiple Encryption Layers**
```bash
# Layer 1: Age encryption for convenience
age -e -R recipients.txt < oath-secrets.txt > oath.age

# Layer 2: Additional encryption with different key/method
gpg --symmetric --cipher-algo AES256 oath.age

# Result: Two different decryption methods available
```

**Option 3: SOPS with Multiple Keys**
```yaml
# .sops.yaml - Multiple key types for redundancy
keys:
  - &yubikey_piv age1yubikey1...  # YubiKey PIV
  - &backup_key age1...           # Separate age identity
  - &gpg_key 0x...               # Non-YubiKey GPG key

creation_rules:
  - path_regex: \.yaml$
    key_groups:
      - age:
          - *yubikey_piv
          - *backup_key
        pgp:
          - *gpg_key
```

#### **📋 Recommended Age/SOPS Strategy**

**1. Two-Tier Approach:**
- **Tier 1**: Age/SOPS for convenience and automation
- **Tier 2**: Offline storage for ultimate recovery

**2. Identity Management:**
```bash
# Primary identity (YubiKey PIV)
age-plugin-yubikey --identity  # For daily use

# Emergency identity (separate hardware)
age-keygen > emergency-key.txt  # Store on separate device
```

**3. Backup Script Example:**
```bash
#!/bin/bash
# Safe YubiKey backup with Age

# Non-critical data (use YubiKey PIV)
age -e -R ~/.config/age/recipients.txt < config-data.txt > config.age

# Critical data (use emergency identity)
age -e -i ~/.config/age/emergency-identity.txt < oath-secrets.txt > oath.age

# Always maintain offline copies
cp oath-secrets.txt /secure-offline-storage/
cp emergency-identity.txt /separate-secure-location/
```

#### **🎯 Summary: When to Use Age/SOPS**

**✅ Good for:**
- Configuration files and setup notes
- Public keys and non-secret references  
- Service account mappings
- Automation of routine backups
- Encrypted storage of convenience copies

**⚠️ Careful with:**
- OATH/TOTP secrets (avoid circular dependencies)
- Any data needed for YubiKey recovery
- Critical system recovery data

**❌ Never for:**
- GPG master secret keys
- LUKS headers (primary copies)
- Age/SOPS identity keys themselves
- Single-point-of-failure recovery data

**Best Practice:** Use Age/SOPS as a **convenience layer** on top of, not instead of, offline secure storage.

### 1. GPG Master Key and Subkeys
```bash
# 🔒 BACKUP: Export master secret key (OFFLINE STORAGE ONLY!)
gpg --export-secret-keys --armor YOUR_KEY_ID > master-secret-key.asc

# 🔒 BACKUP: Export secret subkeys
gpg --export-secret-subkeys --armor YOUR_KEY_ID > secret-subkeys.asc

# 🔒 BACKUP: Export public key (safe to share)
gpg --export --armor YOUR_KEY_ID > public-key.asc

# 🔒 BACKUP: Export SSH public key from GPG
gpg --export-ssh-key YOUR_KEY_ID > yubikey-ssh-public.key

# 🔒 BACKUP: Export revocation certificate
gpg --gen-revoke YOUR_KEY_ID > revocation-certificate.asc
```

**Storage Requirements:**
- Store `master-secret-key.asc` on **OFFLINE media only** (encrypted USB, paper backup)
- Store `secret-subkeys.asc` on **encrypted backup drive**
- Keep `revocation-certificate.asc` in **separate secure location**
- Store `public-key.asc` and `yubikey-ssh-public.key` in **password manager**

### 2. LUKS Recovery Information
```bash
# 🔒 BACKUP: LUKS header (critical for recovery)
sudo cryptsetup luksHeaderBackup /dev/nvme0n1p2 --header-backup-file luks-header-backup.img

# 🔒 BACKUP: Record LUKS UUID
sudo cryptsetup luksDump /dev/nvme0n1p2 | grep UUID > luks-uuid.txt

# 🔒 BACKUP: YubiKey challenge used for LUKS
echo "CHALLENGE_USED_FOR_LUKS" > yubikey-luks-challenge.txt
```

**Storage Requirements:**
- Store `luks-header-backup.img` on **encrypted external drive**
- Keep `luks-uuid.txt` and `yubikey-luks-challenge.txt` in **password manager**
- Test recovery procedure on **non-production system**

### 3. OATH/TOTP Backup Codes
```bash
# 🔒 BACKUP: Export all OATH accounts
for account in $(ykman oath accounts list); do
    echo "=== $account ===" >> oath-backup.txt
    ykman oath accounts uri "$account" >> oath-backup.txt
    echo "" >> oath-backup.txt
done

# 🔒 BACKUP: Generate QR codes for manual entry
ykman oath accounts uri --qr "GitHub:username" > github-qr.png
```

**Storage Requirements:**
- Store `oath-backup.txt` in **encrypted password manager**
- Print QR codes and store in **physical safe**
- Keep service-specific backup codes in **separate secure notes**

### 4. SSH Key Backups
```bash
# 🔒 BACKUP: Traditional SSH keys (if using PIV method)
cp ~/.ssh/id_rsa ~/.ssh/id_rsa.pub ~/secure-backup/

# 🔒 BACKUP: FIDO2 SSH public keys
cp ~/.ssh/id_ed25519_sk.pub ~/secure-backup/

# 🔒 BACKUP: SSH configuration
cp ~/.ssh/config ~/secure-backup/
```

### 5. YubiKey Configuration Backup
```bash
# 🔒 BACKUP: YubiKey device information
ykman info > yubikey-info.txt
ykman otp info >> yubikey-info.txt
ykman piv info >> yubikey-info.txt

# 🔒 BACKUP: U2F registration data
cp ~/.config/Yubico/u2f_keys ~/secure-backup/
```

## 🗑️ Security Cleanup Checklist

⚠️ **THESE FILES MUST BE SECURELY DELETED AFTER SETUP** ⚠️

### 1. Immediate Cleanup (After Each Step)
```bash
# 🗑️ DELETE: Temporary LUKS key files
shred -vfz /tmp/yk-luks-key
shred -vfz /tmp/luks-challenge.txt

# 🗑️ DELETE: Temporary GPG files
shred -vfz /tmp/pubkey.pem
rm -f /tmp/gpg-*

# 🗑️ DELETE: Challenge response test files
rm -f /tmp/test-challenge*
```

### 2. GPG Key Cleanup (CRITICAL!)
```bash
# 🗑️ DELETE: Secret keys from host after moving to YubiKey
# WARNING: Only do this AFTER confirming keys work on YubiKey!

# Verify keys are on YubiKey first
gpg --card-status
ykman piv info

# Only then remove from host
gpg --delete-secret-keys YOUR_KEY_ID
# Keep public key for verification:
# gpg --delete-keys YOUR_KEY_ID  # DON'T do this unless you have backups

# Clear GPG agent cache
gpgconf --kill gpg-agent
```

### 3. SSH Key Cleanup
```bash
# 🗑️ DELETE: Private SSH keys if using YubiKey exclusively
# WARNING: Only after confirming YubiKey SSH works!

# Test YubiKey SSH first
ssh -i ~/.ssh/id_ed25519_sk user@testserver

# Only then remove traditional keys
shred -vfz ~/.ssh/id_rsa
shred -vfz ~/.ssh/id_ecdsa
# Keep public keys for reference
```

### 4. Development Files Cleanup
```bash
# 🗑️ DELETE: Backup text files with sensitive data
shred -vfz oath-backup.txt
shred -vfz github-backup.txt
shred -vfz *-secret-key.asc  # Only after secure storage!

# 🗑️ DELETE: Browser saved passwords (use YubiKey instead)
# Clear saved passwords in Firefox/Chrome
# Remove password manager database if migrating to YubiKey-secured version
```

### 5. Shell History Cleanup
```bash
# 🗑️ DELETE: Commands with secrets from shell history
history -c  # Clear current session
shred -vfz ~/.bash_history ~/.zsh_history
# Or edit to remove sensitive commands:
# sed -i '/ykman.*add/d' ~/.zsh_history
# sed -i '/echo.*SECRET/d' ~/.zsh_history
```

### 6. System Logs Cleanup
```bash
# 🗑️ DELETE: Logs that might contain secrets
sudo journalctl --vacuum-time=1d  # Keep only last day
sudo find /var/log -name "*.log" -exec shred -vfz {} \; 2>/dev/null
```

### 7. Secure Deletion Verification
```bash
# 🔍 VERIFY: Check for remaining secret data
sudo grep -r "SECRET_KEY\|PRIVATE_KEY\|BEGIN.*PRIVATE" /home/$USER/ 2>/dev/null
sudo find /tmp -name "*secret*" -o -name "*private*" 2>/dev/null

# 🔍 VERIFY: Check GPG keyring
gpg --list-secret-keys  # Should show YubiKey entries only

# 🔍 VERIFY: Check SSH agent
ssh-add -l  # Should show YubiKey or no keys
```

## ⚠️ Critical Security Reminders

### Before You Start
- [ ] **Set up offline backup system** (encrypted USB, hardware wallet, etc.)
- [ ] **Test backup and recovery procedures** on non-production systems
- [ ] **Document your setup** including PINs, slot usage, service accounts
- [ ] **Prepare second YubiKey** for redundancy

### During Setup
- [ ] **Work in private environment** (no screen sharing, recording, or observers)
- [ ] **Disconnect from internet** when handling master keys
- [ ] **Use secure terminal** (avoid saving history for sensitive commands)
- [ ] **Verify each step** before proceeding to next

### After Setup
- [ ] **Secure backup storage** verified and tested
- [ ] **Host system cleaned** of all temporary secrets
- [ ] **Recovery procedure documented** and tested
- [ ] **YubiKey functionality verified** across all use cases
- [ ] **Service accounts updated** with YubiKey authentication
- [ ] **Old authentication methods disabled** where appropriate

## Security Best Practices

### 1. PIN Management
```bash
# Change default PINs immediately
ykman piv access change-pin    # Default: 123456
ykman piv access change-puk    # Default: 12345678
ykman oath access change-password  # Set OATH password
```

### 2. Backup Strategy
- **Keep backup YubiKey** with identical configuration
- **Export public keys** and store securely
- **Document your setup** including slot usage
- **Store recovery codes** for services offline

### 3. Physical Security
- **Attach to keychain** or wear as jewelry
- **Use lanyard/retractable cable** when working
- **Never leave unattended** in computer
- **Report loss immediately** and revoke access

### 4. Multi-Device Setup
```bash
# Configure multiple YubiKeys identically
# Export/import OATH accounts between keys
ykman oath accounts uri ACCOUNT > account-backup.txt
# Import on second YubiKey:
ykman oath accounts add-uri < account-backup.txt
```

## Troubleshooting

### Common Issues

#### YubiKey Not Detected
```bash
# Check USB connection
lsusb | grep Yubico

# Check permissions
ls -la /dev/bus/usb/*/

# Restart udev
sudo udevadm control --reload-rules
sudo udevadm trigger
```

#### GPG Agent Issues
```bash
# Kill and restart GPG agent
gpgconf --kill gpg-agent
gpgconf --launch gpg-agent

# Check agent status
gpg --card-status
```

#### SSH Key Not Working
```bash
# Check SSH agent
ssh-add -l

# Test PKCS#11
ssh-keygen -D /usr/lib/x86_64-linux-gnu/libykcs11.so -e

# Test FIDO2
ssh-keygen -K  # Download resident keys
```

#### PAM U2F Failures
```bash
# Check PAM configuration
sudo pam-auth-update

# Test U2F manually
pamu2fcfg -d

# Check logs
journalctl -f | grep pam
```

### Emergency Recovery

#### Lost YubiKey
1. **Immediately revoke access** from all services
2. **Use backup YubiKey** if configured
3. **Generate new keys** and update services
4. **Review access logs** for unauthorized use

#### Forgotten PIN/Password
1. **Use PUK to reset PIN** (PIV applications)
2. **Factory reset** as last resort (loses all data)
3. **Restore from backups** if available

## NixOS Integration Example

Complete NixOS configuration for YubiKey support:

```nix
{ config, pkgs, ... }:

{
  # YubiKey support packages
  environment.systemPackages = with pkgs; [
    yubikey-manager
    yubikey-personalization
    libfido2
    pam_u2f
    gnupg
    pinentry-gtk2
  ];

  # GPG agent configuration
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
    pinentryPackage = pkgs.pinentry-gtk2;
  };

  # PAM U2F support
  security.pam.u2f = {
    enable = true;
    settings = {
      cue = true;
      interactive = true;
    };
  };

  # Enable U2F for various services
  security.pam.services = {
    login.u2fAuth = true;
    sudo.u2fAuth = true;
    polkit-1.u2fAuth = true;
  };

  # SSH server with FIDO2 support
  services.openssh = {
    enable = true;
    settings = {
      PubkeyAuthentication = true;
      AuthenticationMethods = "publickey";
    };
  };

  # LUKS with YubiKey support
  boot.initrd.luks.devices."cryptroot" = {
    device = "/dev/disk/by-uuid/your-uuid-here";
    yubikey = {
      slot = 2;
      twoFactor = true;
      gracePeriod = 2;
    };
  };

  # udev rules for YubiKey
  services.udev.packages = with pkgs; [
    yubikey-personalization
    libfido2
  ];

  # Environment variables
  environment.sessionVariables = {
    GPG_TTY = "$(tty)";
  };
}
```

This comprehensive setup provides security for disk encryption, authentication, 2FA, and secure communications using your YubiKey across your entire NixOS system.