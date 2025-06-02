{
  stdenv,
  lib,
  fetchurl,
  makeWrapper,
  dpkg,
  systemd,
  libselinux,
  libcxx,
  minizip-ng,
  curl,
  libseccomp,
  libuuid,
  openssl,
  gcc,
  libcap,
  acl,
  zlib,
  gzip,
  fuse,
  sqlite,
  coreutils,
  gnugrep,
  pcre2,
  nixosTests,
}:
let
  libPath = lib.makeLibraryPath [
    systemd
    libselinux
    libcxx
    minizip-ng
    curl
    libseccomp
    libuuid
    openssl
    gcc.cc.lib # Specifically for libatomic
    libcap
    acl
    zlib
    fuse
    sqlite
    pcre2
  ];
in
stdenv.mkDerivation rec {
  pname = "mdatp";
  version = "101.25042.0002";
  src = fetchurl {
    url = "https://packages.microsoft.com/ubuntu/24.04/prod/pool/main/m/${pname}/${pname}_${version}_amd64.deb";
    hash = "sha256-hKbABEAykANddyDDRktafjv/y1eLaXAgvTjt0FQVtjI=";
  };

  nativeBuildInputs = [ dpkg makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -ar opt/microsoft/mdatp/sbin $out/sbin
    ln -s $out/sbin/wdavdaemonclient $out/bin/mdatp

    # Copy internal libs
    cp -ar opt/microsoft/mdatp/lib $out/lib

    # Copy configuration
    cp -ar opt/microsoft/mdatp/conf $out/conf
    cp -ar opt/microsoft/mdatp/resources $out/resources
    cp -ar opt/microsoft/mdatp/definitions $out/definitions

    # Patch binaries
    for executable in $out/bin/mdatp $out/sbin/*; do
      wrapProgram $executable \
        --set-default NIX_LD $(cat $NIX_CC/nix-support/dynamic-linker) \
        --prefix NIX_LD_LIBRARY_PATH : $out/lib:${libPath} \
        --prefix PATH : ${lib.makeBinPath [ coreutils gnugrep ]} ;
    done
    # Install completions
    mkdir -p $out/share/bash-completion/completions $out/share/zsh/site-functions

    cp opt/microsoft/mdatp/resources/mdatp_completion.bash $out/share/bash-completion/completions/mdatp
    cp opt/microsoft/mdatp/resources/mdatp_completion.zsh $out/share/zsh/site-functions/_mdatp

    runHook postInstall
  '';

  dontPatchELF = true;

  /*passthru = {
    updateScript = ./update.sh;
    tests = { inherit (nixosTests) intune; };
  };*/

  meta = with lib; {
    description = "Microsoft Defender Advanced Threat Protection for Endpoints";
    homepage = "https://www.microsoft.com/";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with lib.maintainers; [ epetousis ];
  };
}
