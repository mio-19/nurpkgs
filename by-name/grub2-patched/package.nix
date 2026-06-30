{
  pkgs,
  grub2,
}:

let
  private = import ../../private.nix { inherit pkgs; };
in
private.nodarwin (
  private.v3overridegcc (
    grub2.overrideAttrs (old: {
      pname = "grub2-patched";
      patches = (old.patches or [ ]) ++ [ ./grub-os-prober-title.patch ];
    })
  )
)
