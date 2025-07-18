# User-level secrets for your-username in work context
# These secrets are managed by Home Manager and owned by the user

let
  # Add your age public key here (generate with: age-keygen)
  user1 = "age1abc123your-age-public-key-here";
  
  # You can add more users/keys for team access
  # user2 = "age1def456another-user-key";
  
  # Define which keys can access which secrets
  allUsers = [ user1 ];
in
{
  # User-level secrets
  "ssh-work-key.age".publicKeys = allUsers;        # SSH private key for work
  "gpg-private-key.age".publicKeys = allUsers;     # GPG private key
  "api-tokens.age".publicKeys = allUsers;          # Personal API tokens
  "git-credentials.age".publicKeys = allUsers;     # Git hosting credentials
  
  # Application-specific user secrets
  # "docker-credentials.age".publicKeys = allUsers; # Docker registry auth
  # "aws-credentials.age".publicKeys = allUsers;    # AWS access keys
  # "work-2fa-backup.age".publicKeys = allUsers;    # 2FA backup codes
}
