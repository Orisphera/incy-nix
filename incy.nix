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

    # AWT reads the reparenting hint via native getenv(). On non-reparenting
    # WMs over XWayland (niri), the WM's ConfigureNotify resize is dropped at
    # map-time, so Compose renders at a fixed initial size leaving black margin.
    cat > $out/bin/incy <<EOF
#!/bin/sh
export _JAVA_AWT_WM_NONREPARENTING=1
exec $out/incy/bin/incy "\$@"
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