# incy-nix

> A NixOS wrapper for [INCY Desktop](https://github.com/INCY-DEV/incy-platforms) — a Kotlin/JVM (JetBrains Compose) VPN client powered by Xray-core.

Built from the official `incy-linux-x64.pkg.tar.zst` release, unpacked into the Nix store, with working **privileged TUN helper** (pkexec/polkit) support on NixOS.

## Quick start

```console
# Run GUI directly
nix run github:f1v3nt5/incy-nix
```

## Flake outputs

| Output | Description |
| --- | --- |
| `packages.x86_64-linux.incy` | INCY package (GUI + Xray + helper) |
| `packages.x86_64-linux.default` | Same as above |
| `apps.x86_64-linux.default` | Launches the INCY GUI |
| `overlays.default` | Overlay providing `pkgs.incy` |
| `nixosModules.default` | NixOS module with polkit/TUN/DNS support |

## Installing on NixOS

```nix
{
  inputs.incy-nix.url = "github:f1v3nt5/incy-nix";

  outputs = { nixpkgs, incy-nix, ... }: {
    nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
      modules = [
        incy-nix.nixosModules.default
        { programs.incy.enable = true; }
      ];
    };
  };
}
```

### Module options

| Option | Default | Description |
| --- | --- | --- |
| `programs.incy.enable` | `false` | Enables the INCY GUI |
| `programs.incy.package` | `incy` | Custom INCY package |
| `programs.incy.polkit.enable` | `false` | Polkit + pkexec wrapper for the privileged helper |
| `programs.incy.tun.enable` | `false` | TUN driver + `/dev/net/tun` + firewall trust |
| `programs.incy.dns.enable` | `false` | Enables systemd-resolved for `resolvectl` DNS capture |

### Full privileged tunnel

```nix
programs.incy = {
  enable = true;
  polkit.enable = true;
  tun.enable = true;
  dns.enable = true;
};
```

Enables:
- `security.polkit` with the setuid `pkexec` wrapper (`/run/wrappers/bin/pkexec`, which the INCY GUI probes for).
- The polkit action `cc.incy.vpn.run-helper` policy (shipped in the package).
- A symlink `/usr/lib/incy/incy-helper-linux.sh` → the packaged helper.
- `tun` kernel module + `/dev/net/tun` device node, and firewall trust for `wwan99`.
- `services.resolved` so the helper uses `resolvectl` instead of rewriting `/etc/resolv.conf`.

## Notes

- Only `x86_64-linux` is supported.
- The client is JVM/Compose (X11/Skiko), so **XWayland** is enabled via the module. A tray/StatusNotifier host is not required for basic use.
- The privileged helper is invoked via `pkexec`; the user must be in the `wheel` group for `auth_admin_keep`.
- Kill-switch uses `iptables` (chain `INCY_KILLSWITCH`) — may need its own policy for silent operation.

## License

[MIT](LICENSE)