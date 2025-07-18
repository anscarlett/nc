# Centralized password management with agenix support
{ config, lib }:
let
  # Use agenix secret if available, fallback to default hash
  getPasswordHash = secretPath: defaultHash:
    if config ? age && config.age.secrets ? ${secretPath}
    then config.age.secrets.${secretPath}.path
    else defaultHash;
in
{
  # Default password hash for development/testing (password: "nixos")
  defaultHash = "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  
  # Get secure password hash (prefers agenix secret)
  secureHash = getPasswordHash "default-password" "$6$hUZs3UqzsRWgkcP/$6iooTMSWqeFwn12p9zucgvNGuKIqPSFXX5dgKrxpnp7JfyFogP/hup8/0x3ihIIaXZS.t68/L8McEk23WXJLj/";
  
  # Helper function to set the same password for multiple users
  setPasswordForUsers = usernames: hash: 
    builtins.listToAttrs (map (username: {
      name = username;
      value = { hashedPasswordFile = hash; };
    }) usernames);
    
  # Helper to set secure password for all auto-discovered users
  setSecurePasswordForAllUsers = homesDir:
    let
      mkConfigs = import ./mk-configs.nix { inherit lib; };
      homes = mkConfigs.mkHomes homesDir;
      usernames = builtins.attrNames homes;
    in
    builtins.listToAttrs (map (username: {
      name = username;
      value = { hashedPasswordFile = getPasswordHash "default-password" null; };
    }) usernames);
}
