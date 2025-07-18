# System-level secrets for rock5b host
# These secrets are managed by NixOS

let
  # Add age public keys for users who can access these secrets
  # adrian = "age1..."; # Your age public key
  
  # Define which keys can access which secrets
  allUsers = [ 
    # adrian 
  ];
in
{
  # System-level secrets for this host
  # "home-wifi.age".publicKeys = allUsers;           # WiFi credentials for NetworkManager
  # "ssh-host-keys.age".publicKeys = allUsers;       # SSH host keys for consistency
  # "monitoring-token.age".publicKeys = allUsers;    # Monitoring service tokens
  
  # Server-specific secrets
  # "backup-key.age".publicKeys = allUsers;          # Backup encryption key
  # "api-keys.age".publicKeys = allUsers;            # Service API keys
}
