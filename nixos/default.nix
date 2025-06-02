{ config, lib, pkgs, ... }:

let
  cfg = config.services.mdatp;
  startPreScript = pkgs.writeScript "init-mdatp" ''
    #!${pkgs.bash}/bin/bash
    set -euo pipefail
    INSTALL=/opt/microsoft/mdatp
    PATH=${lib.makeBinPath (with pkgs; [ coreutils gnugrep gzip ])}
    mkdir -p /boot && zcat /proc/config.gz > /boot/config-$(uname -r)  # wdavdaemon checks for this file
    # Create parent directory for $INSTALL symlink
    mkdir -p /opt/microsoft
    if [[ -e $INSTALL ]]; then
      if [[ -L $INSTALL ]]; then
        if [[ $(readlink $INSTALL) != $INSTALL ]]; then
          rm $INSTALL
        fi
      else
        echo "oops, $INSTALL is already installed?"
        exit -1
      fi
    fi
    if [[ ! -e $INSTALL ]]; then
      ln -s -T ${cfg.package} $INSTALL
    fi
  '';
in {
  options.services.mdatp = {
    enable = lib.mkEnableOption "Whether to enable Microsoft Defender Advanced Threat Protection.";
    package = lib.mkPackageOption pkgs "mdatp" { };
    enableBashIntegration = lib.mkEnableOption "Enable Bash integration" // {
      default = false;
    };
    enableZshIntegration = lib.mkEnableOption "Enable Zsh integration" // {
      default = false;
    };
  };

  config = lib.mkIf cfg.enable {
    nixpkgs.overlays = [ (import ../overlay.nix) ];

    environment.systemPackages = [ cfg.package ];

    users.users.mdatp = {
      group = "mdatp";
      isSystemUser = true;
    };

    users.groups.mdatp = { };

    programs.nix-ld.enable = lib.mkForce true;  # nix-ld is required for mdatp to function without tripping anti-tamper measures
    programs.bash.interactiveShellInit = lib.mkIf cfg.enableBashIntegration "source ${cfg.package}/resources/mdatp_completion.bash # enable shell integration for mdatp";
    # TODO: this seems like a hack, as having this enabled gets the following error:
    # "_arguments:comparguments:327: can only be called from completion function"
    programs.zsh.interactiveShellInit  = lib.mkIf cfg.enableZshIntegration  "source ${cfg.package}/resources/mdatp_completion.zsh  # enable shell integration for mdatp";

    systemd.services.mdatp = {
      enable = true;
      description = "Microsoft Defender Advanced Threat Protection Daemon";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStartPre = startPreScript;
        WorkingDirectory = "${cfg.package}/sbin";
        ExecStart = "${cfg.package}/sbin/wdavdaemon";
        NotifyAccess="main";
        LimitNOFILE=65536;
        # Limit number of arena used by malloc
        Environment=["MALLOC_ARENA_MAX=2" "ENABLE_CRASHPAD=1"];
        # Restart on non-successful exits.
        Restart="always";
        # all available cgroup controllers are enabled and not influenced by systemd
        Delegate="yes";
      };
      unitConfig = {
        DefaultDependencies = false;
        # Don't restart if we've restarted more than 3 times in 2 minutes.
        StartLimitInterval=120;
        StartLimitBurst=3;
      };
    };

  };

  meta = {
    maintainers = with lib.maintainers; [ epetousis ];
  };
}
