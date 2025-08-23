# System-level secrets for vm-test host
# These secrets are managed by NixOS - mostly for testing purposes

let
  # Add age public keys for users who can access these secrets
  # testuser = "age1..."; # Your age public key
  
  # Define which keys can access which secrets
  allUsers = [ 
    # testuser 
  ];
in
{
  # VM testing secrets (usually minimal for testing)
  # "test-wifi.age".publicKeys = allUsers;           # Test WiFi credentials
  # "test-certs.age".publicKeys = allUsers;          # Test certificates
  
  # VM-specific secrets for development/testing
  # "dev-api-key.age".publicKeys = allUsers;         # Development API keys
  # "test-data.age".publicKeys = allUsers;           # Test datasets
}
