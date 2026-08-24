{ pkgs, lib }:

pkgs.stdenv.mkDerivation rec {
  pname = "incy-desktop";
  version = "3.6.0";

  src = pkgs.fetchurl {
    url = "https://github.com/INCY-DEV/incy-platforms/releases/download/desktop-v${version}/incy-linux-x64.pkg.tar.zst";
    sha256 = "5c14889583568318ce6f75f24298389cf61c9522143b0f18aa6025a08a53b91d";
  };

  nativeBuildInputs = with pkgs; [
    autoPatchelfHook
    stdenv.cc.cc
    zstd
  ];

  buildInputs = with pkgs; [
    libX11
    libXrender
    libXtst
    libXi
    libXext
    libxcb
    zlib
    alsa-lib
    libGL
    fontconfig
  ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out

    zstd -d "$src" -o $src.tar

    tar xf $src.tar

    mkdir -p $out

    cp -r opt/incy $out/

    if [ -d usr/share ]; then
      mkdir -p $out/share
      cp -r usr/share/* $out/share/
    fi

    mkdir -p $out/bin

    # incy is a Kotlin/Compose Desktop app rendered through Skiko. On Wayland
    # compositors (niri, Hyprland, sway) it runs via XWayland, where the default
    # OpenGL redrawer mis-sizes its framebuffer when the WM resizes the window:
    # the UI ends up drawn in the top-left corner and the rest of the window is
    # black. Two things are needed to make it behave:
    #   * _JAVA_AWT_WM_NONREPARENTING=1 — AWT must know the WM does not reparent
    #     windows (true for Wayland/tiling compositors), otherwise it never
    #     tracks resize events and the surface stays at its initial size.
    #   * SKIKO_RENDER_API=SOFTWARE — force Skiko's CPU renderer instead of the
    #     broken GLX/OpenGL path under XWayland.
    cat > $out/bin/incy <<EOF
#!/bin/sh
export _JAVA_AWT_WM_NONREPARENTING=1
export SKIKO_RENDER_API=SOFTWARE
exec "$out/incy/bin/incy" "\$@"
EOF
    chmod +x $out/bin/incy

    substituteInPlace \
      $out/share/applications/incy.desktop \
      --replace-fail "/opt/incy/bin/incy" "$out/bin/incy"

    runHook postInstall
  '';

  meta = with lib; {
    description = "INCY Desktop VPN client (Xray-based)";
    homepage = "https://github.com/INCY-DEV/incy-platforms";
    platforms = platforms.linux;
    mainProgram = "incy";
  };
}