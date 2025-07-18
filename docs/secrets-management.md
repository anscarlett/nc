# Secrets Management Guide

This configuration uses **co-located secrets** - secrets are stored alongside the configurations that use them, not in a global location.

## 🏗️ Architecture Principle

**Co-located secrets** means:
- **Host secrets** → `hosts/context/hostname/secrets.nix` (for system-level secrets)
- **User secrets** → `homes/context/username/secrets.nix` (for user-level secrets)
- **No global secrets file** → Each secret is owned by the specific host or user that needs it

## 📁 Secrets Location Examples

```
hosts/
├── home/legion/
│   ├── host.nix           # System configuration
│   └── secrets.nix        # System secrets (WiFi, VPN, SSL certs)
├── work/laptop/
│   ├── host.nix           # System configuration
│   └── secrets.nix        # Work system secrets
│
homes/
├── home/adrian/
│   ├── home.nix           # User configuration
│   └── secrets.nix        # Personal secrets (SSH keys, API tokens)
├── work/adrianscarlett/
│   ├── home.nix           # Work user configuration
│   └── secrets.nix        # Work user secrets
```

## 🔐 Secret Types

### System Secrets (`hosts/*/secrets.nix`)
- WiFi passwords
- VPN configurations
- SSL certificates
- System service credentials
- Disk encryption keys

### User Secrets (`homes/*/secrets.nix`)
- SSH private keys
- API tokens
- Personal credentials
- Application-specific secrets

## 🛠️ Setting Up Secrets

### 1. Create Host Secrets

For each host that needs secrets:

```bash
# Create secrets file for a host
mkdir -p hosts/home/legion
cat > hosts/home/legion/secrets.nix << 'EOF'
{
  # WiFi configuration
  "wifi-password.age".publicKeys = [
    "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"  # Host key
    "age1lggyhqrw2nlhcxprm67z43rng0l6w3qqts9fw6mrqr1jyq5u3kqqfzxr5m"  # User key
  ];
  
  # VPN credentials
  "vpn-config.age".publicKeys = [
    "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"
  ];
}
EOF
```

### 2. Create User Secrets

For each user that needs secrets:

```bash
# Create secrets file for a user
mkdir -p homes/home/adrian
cat > homes/home/adrian/secrets.nix << 'EOF'
{
  # SSH private key
  "ssh-key.age".publicKeys = [
    "age1lggyhqrw2nlhcxprm67z43rng0l6w3qqts9fw6mrqr1jyq5u3kqqfzxr5m"  # User key
    "age1ql3z7hjy54pw3hyww5ayyfg7zqgvc7w3j2elw8zmrj2kg5sfn9aqmcac8p"  # Host key (for recovery)
  ];
  
  # API tokens
  "github-token.age".publicKeys = [
    "age1lggyhqrw2nlhcxprm67z43rng0l6w3qqts9fw6mrqr1jyq5u3kqqfzxr5m"
  ];
}
EOF
```

## 🔑 Key Management

### Generate Age Keys

1. **Install agenix**:
```bash
nix profile install github:ryantm/agenix
```

2. **Generate keys from existing SSH keys**:
```bash
# Convert SSH key to age key
ssh-to-age < ~/.ssh/id_ed25519.pub
```

3. **Or generate native age keys**:
```bash
age-keygen
```

### Key Distribution Strategy

- **Personal keys**: Use your SSH public key converted to age format
- **System keys**: Generate dedicated age keys for each host
- **YubiKey integration**: Use age-plugin-yubikey for hardware-backed keys

## 📝 Using Secrets in Configurations

### In Host Configurations

```nix
# hosts/home/legion/host.nix
{
  # Import the co-located secrets
  age.secrets = import ./secrets.nix;
  
  # Use secrets in configuration
  networking.wireless.networks."MyWiFi".pskFile = config.age.secrets."wifi-password".path;
}
```

### In Home Configurations

```nix
# homes/home/adrian/home.nix
{
  # Import the co-located secrets
  age.secrets = import ./secrets.nix;
  
  # Use secrets in configuration
  programs.ssh.extraConfig = ''
    IdentityFile ${config.age.secrets."ssh-key".path}
  '';
}
```

## 🔄 Migration from Global Secrets

If you have existing global secrets, migrate them:

1. **Identify secret ownership**: Which secrets belong to which hosts/users?
2. **Move secrets to appropriate locations**: Create `secrets.nix` files alongside configurations
3. **Update references**: Change imports from global to local secret files
4. **Remove global secrets file**: Delete any centralized secrets files

## 🔍 Benefits of Co-located Secrets

- **Clear ownership**: Easy to see which secrets belong to which configuration
- **Easier management**: Secrets live with their configurations
- **Better security**: Principle of least privilege - only relevant entities have access
- **Simplified backups**: Secrets and configurations are backed up together
- **No global state**: No central secrets file that becomes a bottleneck

## 🚨 Security Best Practices

1. **Unique keys per context**: Different keys for home vs work environments
2. **Regular rotation**: Rotate keys periodically
3. **Backup strategy**: Ensure you can recover secrets if needed
4. **Access control**: Only grant access to keys that are actually needed
5. **YubiKey integration**: Use hardware keys for critical secrets

## 📚 Examples

See the existing host and home configurations for examples of co-located secrets:
- `hosts/home/legion/secrets.yaml` (using sops)
- `hosts/work/laptop/secrets.nix` (using agenix)
- `homes/*/secrets.nix` (user-specific secrets)

This approach scales naturally as you add more hosts and users, maintaining clear separation of concerns.
