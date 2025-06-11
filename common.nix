# Common NixOS configuration for all hosts
{ config, ... }:
{
  # Set the system time zone
  time.timeZone = "Europe/London";

  # Set system-wide locale and language
  i18n.defaultLocale = "en_GB.UTF-8";
  i18n.extraLocaleSettings = {
    LC_TIME = "en_GB.UTF-8";
    LC_MONETARY = "en_GB.UTF-8";
    LC_PAPER = "en_GB.UTF-8";
    LC_MEASUREMENT = "en_GB.UTF-8";
  };
}
