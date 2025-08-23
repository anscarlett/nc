# Configuration validation helpers
{ lib }:

{
  # Validate that user passwords are properly set
  validateUserPasswords = users:
    let
      usersWithoutPasswords = lib.filterAttrs (name: user: 
        !(user ? hashedPassword) || user.hashedPassword == null
      ) users;
      
      userNames = lib.attrNames usersWithoutPasswords;
    in
      if userNames != [] then
        throw ''
          ERROR: The following users don't have passwords set:
          ${lib.concatStringsSep ", " userNames}
          
          You must set a password for each user before deploying.
          Generate password hash with:
          
            nix-shell -p mkpasswd --run 'mkpasswd -m sha-512 yourpassword'
          
          Then add to your host.nix:
          
            users.users.USERNAME.hashedPassword = "GENERATED_HASH";
        ''
      else users;

  # Validate disk device exists and is properly formatted
  validateDiskDevice = device:
    if device == null || device == "" then
      throw ''
        ERROR: Disk device not specified in disko configuration.
        
        You must set the disk device in your host.nix:
        
          (import ../../modules/disko.nix {
            disk = "/dev/nvme0n1";  # Your actual disk device
            luksName = "cryptroot";
            enableYubikey = true;
          })
      ''
    else if !lib.hasPrefix "/dev/" device then
      throw ''
        ERROR: Disk device "${device}" doesn't look like a valid device path.
        
        Use a proper device path like:
          /dev/nvme0n1
          /dev/sda
          /dev/disk/by-id/nvme-Samsung_SSD_980_1TB
      ''
    else device;

  # Warn about example configurations
  warnIfExample = hostname:
    if hostname == "example" then
      lib.warn ''
        WARNING: You're using the example configuration!
        
        This is just a template. You should:
        1. Copy hosts/example to hosts/yourhostname
        2. Copy users/example to users/yourusername  
        3. Customize the configurations
        4. Deploy with: nixos-rebuild switch --flake .#yourhostname
      ''
    else hostname;
}
