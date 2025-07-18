# System-level secrets for work-laptop host
# These secrets are managed by NixOS and owned by system users/groups

let
  # Add your age public key here (generate with: age-keygen)
  user1 = "age1abc123your-age-public-key-here";
  
  # You can add more users/keys for team access
  # user2 = "age1def456another-user-key";
  
  # Define which keys can access which secrets
  allUsers = [ user1 ];
in
{
  # System-level secrets for this host
  "work-wifi.age".publicKeys = allUsers;           # WiFi credentials for NetworkManager
  "vpn-config.age".publicKeys = allUsers;          # VPN configuration files
  "ssl-certs.age".publicKeys = allUsers;           # Corporate SSL certificates
  "ca-bundle.age".publicKeys = allUsers;           # Corporate CA certificate bundle
  
  # Host-specific secrets
  # "backup-keys.age".publicKeys = allUsers;       # Backup encryption keys
  # "monitoring-token.age".publicKeys = allUsers;  # Host monitoring tokens
}
