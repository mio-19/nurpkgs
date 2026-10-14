rec {
  # Add your Home Manager modules here
  default = (
    { ... }:
    {
      imports = [
        miodroid
        toshy
      ];
    }
  );
  miodroid = ./miodroid.nix;
  miodroid-rootless = miodroid;
  toshy = ../by-name/to/toshy/hm-module.nix;
  toshy-hm = toshy;
}
