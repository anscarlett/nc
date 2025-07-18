# System-level secrets for work-laptop host
# These secrets are managed by NixOS

let
  # Add age public keys for users who can access these secrets
  # adrianscarlett = "age1..."; # Your age public key
  
  # Define which keys can access which secrets
  allUsers = [ 
    # adrianscarlett 
  ];
in
{
  # System-level secrets for this host
  # "work-wifi.age".publicKeys = allUsers;           # WiFi credentials for NetworkManager
  # "vpn-config.age".publicKeys = allUsers;          # VPN configuration files
  # "ssl-certs.age".publicKeys = allUsers;           # Corporate SSL certificates
  
  # Host-specific secrets
  # "backup-key.age".publicKeys = allUsers;          # Backup encryption key
  # "luks-keyfile.age".publicKeys = allUsers;        # LUKS keyfile for automated unlocking
}
