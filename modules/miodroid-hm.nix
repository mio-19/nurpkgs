{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.miodroid;
  wipWarning = "programs.miodroid is work in progress: the Home Manager service is experimental and currently requires additional rootless LXC setup.";
in
{
  options.programs.miodroid = {
    enable = lib.mkEnableOption "experimental rootless Miodroid";
    package = lib.mkPackageOption pkgs "miodroid" { };
    workDirectory = lib.mkOption {
      type = lib.types.path;
      default = "${config.xdg.dataHome}/miodroid";
      defaultText = lib.literalExpression ''"\${config.xdg.dataHome}/miodroid"'';
      description = "Writable work directory for the experimental rootless Miodroid instance.";
    };
    instance = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      description = "Optional named Miodroid instance.";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.warn wipWarning {
      home.packages = [ cfg.package ];

      systemd.user.services.miodroid-container = {
        Unit = {
          Description = "Experimental Rootless Miodroid Container";
          After = [ "graphical-session.target" ];
          PartOf = [ "graphical-session.target" ];
        };
        Service = {
          ExecStart = "${cfg.package}/bin/miodroid container start";
          Environment = [
            "MIODROID_ROOTLESS=1"
            "MIODROID_WORK=${cfg.workDirectory}"
          ]
          ++ lib.optional (cfg.instance != null) "MIODROID_INSTANCE=${cfg.instance}";
          Restart = "on-failure";
        };
        Install.WantedBy = [ "graphical-session.target" ];
      };
    }
  );
}
