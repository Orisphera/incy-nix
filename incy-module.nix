{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.programs.incy;
  package = cfg.package;
in
{
  options.programs.incy = {
    enable = lib.mkEnableOption "INCY Desktop VPN client";

    package = lib.mkPackageOption pkgs "incy" { };

    polkit.enable = lib.mkEnableOption "polkit support for the INCY privileged tunnel helper";

    tun.enable = lib.mkEnableOption "INCY TUN mode kernel/network support";

    dns.enable = lib.mkEnableOption "systemd-resolved DNS capture for the INCY tunnel";
  };

  config = lib.mkMerge [
(lib.mkIf cfg.enable {
      environment.systemPackages = [ package ];

      # The JVM/AWT (Skiko) client is X11-based.
      programs.xwayland.enable = true;
    })
    (lib.mkIf (cfg.enable && cfg.polkit.enable) {
      # NixOS polkit provides the setuid pkexec wrapper at /run/wrappers/bin/pkexec,
      # which the INCY GUI probes for.
      security.polkit.enable = true;
      # security.polkit.enablePkexecWrapper = true;
      security.polkit.adminIdentities = [ "unix-group:wheel" ];

      # The polkit policy (action cc.incy.vpn.run-helper) shipped in the package.
      environment.etc."polkit-1/actions/cc.incy.vpn.policy".source =
        "${package}/incy/lib/app/resources/cc.incy.vpn.policy";

      # The helper must be at the path the GUI resolves: /usr/lib/incy/incy-helper-linux.sh
      systemd.tmpfiles.rules = [
        "L+ /usr/lib/incy/incy-helper-linux.sh - - - - ${package}/incy/lib/app/resources/bin/incy-helper-linux.sh"
      ];
    })
    (lib.mkIf (cfg.enable && cfg.tun.enable) {
      # TUN driver + /dev/net/tun device node.
      boot.kernelModules = [ "tun" ];
      systemd.tmpfiles.rules = [
        "d /dev/net - - - -"
        "t /dev/net/tun - - - 0600"
      ];

      # The GUI polls /sys/class/net/wwan99; make sure firewall trusts the TUN.
      networking.firewall.trustedInterfaces = [ "wwan99" ];

      # Routing via ip rule / ip route table needs nftables + iproute2.
      environment.systemPackages = with pkgs; [ iproute2 nftables ];
    })
    (lib.mkIf (cfg.enable && cfg.dns.enable) {
      # Helper prefers resolvectl (systemd-resolved) to avoid clobbering /etc/resolv.conf.
      services.resolved.enable = true;
    })
  ];
}
