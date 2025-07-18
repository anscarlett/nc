# Private NixOS Configuration Template

This template provides a starting point for creating a private NixOS configuration that extends the public [nc repository](https://github.com/anscarlett/nc).

## 🚀 Quick Setup

### 1. Copy Template
```bash
# Copy this entire template to your private repository
cp -r private-template/* /path/to/your/private-repo/
cd /path/to/your/private-repo
```

### 2. Customize Configuration

#### Update User Information
1. **Rename the user folder** to match your actual username:
   ```bash
   # The folder name becomes your username automatically
   mv homes/ct/your-username homes/ct/actual-username
   ```

2. **Update personal details** in `homes/ct/actual-username/home.nix`:
   - `programs.git.userName`
   - `programs.git.userEmail`
   - Username and home directory are automatically derived from folder structure

#### Generate Password Hash
```bash
# Clone the public repo temporarily to use the script
git clone https://github.com/anscarlett/nc temp-nc
./temp-nc/scripts/generate-password.sh your-password
# Copy the hash to hosts/ct/laptop/host.nix
rm -rf temp-nc
```

#### Set Up Secrets (Optional)
```bash
# Generate age key
nix-shell -p age --run 'age-keygen -o ~/.config/age/keys.txt'

# Copy your public key to secrets/secrets.nix
cat ~/.config/age/keys.txt | grep "public key:" | cut -d: -f2 | xargs

# Create encrypted secrets (agenix comes from public-config)
nix run github:anscarlett/nc#agenix -- -e work-wifi.age
nix run github:anscarlett/nc#agenix -- -e work-password.age
```

### 3. Initialize Git Repository
```bash
git init
git add .
git commit -m "Initial private configuration"
git remote add origin git@gitlab.com:username/my-private-nixos.git
git push -u origin main
```

### 4. Build and Deploy
```bash
# Build the configuration
sudo nixos-rebuild switch --flake .#ct-laptop

# Build home manager (if using standalone)
home-manager switch --flake .#actual-username-ct
```

## 📁 Structure Explanation

```
.
├── flake.nix                    # Main flake - imports public config
├── hosts/ct/laptop/host.nix     # Work laptop configuration → ct-laptop
├── homes/ct/actual-username/    # User configuration → actual-username-ct
└── secrets/                     # Encrypted secrets (agenix)
    └── secrets.nix              # Defines who can access what secrets
```

## 🔧 Customization Options

### Desktop Environment
In `hosts/ct/laptop/host.nix`, change the desktop import:
```nix
inputs.public-config.modules.desktop.hyprland  # Wayland compositor
inputs.public-config.modules.desktop.gnome     # GNOME desktop
inputs.public-config.modules.desktop.kde       # KDE Plasma
inputs.public-config.modules.desktop.dwm       # Minimalist tiling WM
```

### Additional Hosts/Users
Create more configurations by adding folders:
```
hosts/home/desktop/host.nix     → home-desktop
homes/home/username/home.nix    → username-home
```

### Work Modules
Create custom modules in `work-modules/` for company-specific needs:
```
work-modules/
├── vpn/default.nix
├── corporate-ca/default.nix
└── monitoring/default.nix
```

## 🔄 Staying Updated

```bash
# Update public configuration
nix flake update public-config

# Update all inputs
nix flake update

# Rebuild with updates
sudo nixos-rebuild switch --flake .#ct-laptop
```

## 🛡️ Security Notes

- **Keep secrets encrypted** - Use agenix or sops-nix for sensitive data
- **Use separate SSH keys** for work and personal repositories
- **Regular backups** of your age keys and encrypted secrets
- **Document setup** for team members who need access

For detailed setup instructions, see the [Private Configuration Guide](../docs/private-config.md) in the public repository.
