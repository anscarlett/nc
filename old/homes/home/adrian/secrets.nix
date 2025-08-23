# User-level secrets for adrian in home context
# These secrets are managed by Home Manager

let
  # Add age public keys for users who can access these secrets
  # adrian = "age1..."; # Your age public key
  
  # Define which keys can access which secrets
  allUsers = [ 
    # adrian 
  ];
in
{
  # User-level secrets for personal use
  # "ssh-personal-key.age".publicKeys = allUsers;    # SSH private key for personal projects
  # "gpg-personal-key.age".publicKeys = allUsers;    # GPG private key for personal use
  # "git-personal-token.age".publicKeys = allUsers;  # Personal Git hosting token
  
  # Personal application secrets
  # "password-store.age".publicKeys = allUsers;      # Password store backup
  # "personal-api-keys.age".publicKeys = allUsers;   # Personal service API keys
  # "crypto-keys.age".publicKeys = allUsers;         # Cryptocurrency wallet keys
}
