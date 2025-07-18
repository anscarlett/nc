# Secrets configuration for agenix
# This file defines which secrets exist and who can decrypt them

let
  # Add your age public key here (generate with: age-keygen)
  user1 = "age1abc123your-age-public-key-here";
  
  # You can add more users/keys for team access
  # user2 = "age1def456another-user-key";
  
  # Define which keys can access which secrets
  allUsers = [ user1 ];
in
{
  # Wi-Fi credentials
  "work-wifi.age".publicKeys = allUsers;
  
  # User password
  "work-password.age".publicKeys = allUsers;
  
  # VPN configuration
  "vpn-config.age".publicKeys = allUsers;
  
  # SSH keys
  "ssh-keys.age".publicKeys = allUsers;
  
  # API tokens, certificates, etc.
  # "api-token.age".publicKeys = allUsers;
  # "ssl-cert.age".publicKeys = allUsers;
}
