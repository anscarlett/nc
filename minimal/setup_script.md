# Setup Instructions

Since this is a pure Nix configuration, there's no impure setup script. Instead, follow these steps:

## 1. Copy and Customize Template

```bash
# Copy example configurations to your own
cp -r hosts/example hosts/mylaptop
cp -r users/example users/myuser

# Edit the configurations:
# - hosts/mylaptop/host.nix: Set disk device and hostname
# - users/myuser/user.nix: Set your name and email
```

## 2. Generate Password Hash

```bash
# Generate password hash
nix-shell -p mkpasswd --run 'mkpasswd -m sha-512'

# Add to hosts/mylaptop/host.nix:
users.users.myuser.hashedPassword = "GENERATED_HASH_HERE";
```

## 3. Configure YubiKey (see docs/YUBIKEY.md for details)

```bash
# Basic YubiKey setup
nix-shell -p yubikey-manager --run 'ykman config usb --enable-all'
nix-shell -p yubikey-manager --run 'ykman otp chalresp --generate 2'
```

## 4. Deploy

```bash
sudo nixos-rebuild switch --flake .#mylaptop
```

## 5. Move to Private Repository (optional)

See docs/PRIVATE.md for setting up a private repository that extends this minimal config.