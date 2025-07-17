device:
  if device == null || device == "" || !builtins.match "^/dev/disk/by-id/.+" device != null
    then abort "Error: 'device' must be set to a valid /dev/disk/by-id/... path"
    else device
