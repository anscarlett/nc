# User-level secrets for adrianscarlett in work context
# These secrets are managed by Home Manager

let
  # Add age public keys for users who can access these secrets
  # adrianscarlett = "age1..."; # Your age public key
  
  # Define which keys can access which secrets
  allUsers = [ 
    # adrianscarlett 
  ];
in
{
  # User-level secrets for work context
  # "ssh-work-key.age".publicKeys = allUsers;        # SSH private key for work
  # "gpg-work-key.age".publicKeys = allUsers;        # GPG private key for work
  # "git-work-token.age".publicKeys = allUsers;      # Git hosting token
  
  # Work-specific application secrets
  # "slack-token.age".publicKeys = allUsers;         # Slack API token
  # "teams-config.age".publicKeys = allUsers;        # Teams configuration
  # "work-2fa-backup.age".publicKeys = allUsers;     # 2FA backup codes
}
