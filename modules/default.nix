rec {
  # Add your NixOS modules here
  #
  # my-module = ./my-module;
  default = (
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      imports = [
        zfs-impermanence-on-shutdown
        darling
        wireguird
        razer-laptop-control
        miodroid
        local-ai
        toshy
      ];
    }
  );
  zfs-impermanence-on-shutdown = ./zfs-impermanence-on-shutdown.nix;
  darling = ./darling.nix;
  wireguird = ./wireguird.nix;
  razer-laptop-control = ./razer-laptop-control.nix;
  miodroid = ./miodroid.nix;
  local-ai = ../by-name/lo/local-ai/module.nix;
  toshy = ../by-name/to/toshy/nixos-module.nix;

  # Backwards-compatibility aliases for Home Manager modules (moved to homeModules)
  toshy-hm = ../by-name/to/toshy/hm-module.nix;
  miodroid-rootless = ../home-modules/miodroid.nix;
}
