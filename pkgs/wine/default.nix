{
  inputs,
  self,
  pins,
  lib,
  build,
  pkgs,
  pkgsCross,
  pkgsi686Linux,
  callPackage,
  fetchFromGitHub,
  fetchurl,
  moltenvk,
  supportFlags,
  stdenv_32bit,
}: let
  nixpkgs-wine = builtins.path {
    path = inputs.nixpkgs;
    name = "source";
    filter = path: type: let
      wineDir = "${inputs.nixpkgs}/pkgs/applications/emulators/wine/";
    in (
      (type == "directory" && (lib.hasPrefix path wineDir))
      || (type != "directory" && (lib.hasPrefix wineDir path))
    );
  };

  defaults = let
    sources = (import "${inputs.nixpkgs}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
  in {
    inherit supportFlags moltenvk;
    patches = [];
    buildScript = "${nixpkgs-wine}/pkgs/applications/emulators/wine/builder-wow.sh";
    configureFlags = ["--disable-tests"];
    geckos = with sources; [gecko32 gecko64];
    mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc mingwW64.buildPackages.gcc];
    monos = with sources; [mono];
    pkgArches = [pkgs pkgsi686Linux];
    platforms = ["x86_64-linux"];
    stdenv = stdenv_32bit;
    wineRelease = "unstable";
  };

  pnameGen = n: n + lib.optionalString (build == "full") "-full";
in {
  wine-ge =
    (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (defaults
      // {
        pname = pnameGen "wine-ge";
        version = pins.proton-wine.branch;
        src = pins.proton-wine;
        wineRelease = "ge";
      }))
    .overrideAttrs (old: {
      meta = old.meta // {passthru.updateScript = ./update-wine-ge.sh;};
    });

  wine-tkg =
    (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix"
      (lib.recursiveUpdate defaults
        rec {
          pname = pnameGen "wine-tkg";
          version = lib.removeSuffix "\n" (lib.removePrefix "Wine version " (builtins.readFile "${src}/VERSION"));
          src = pins.wine-tkg;
        }))
    .overrideDerivation (
      old: {
        NIX_CFLAGS_COMPILE = let
          inherit
            (pkgs.linuxPackages_xanmod_latest)
            kernel
            ;
          headers = pkgs.makeLinuxHeaders {
            inherit (kernel) src;
            inherit (kernel) version;
            inherit (kernel) patches;
          };
        in [
          "-I${headers}/include"
        ];
        buildInputs = with pkgs; [] ++ old.buildInputs;
      }
    );

  wine-osu = let
    pname = pnameGen "wine-osu";
    version = "7.0";
    staging = fetchFromGitHub {
      owner = "wine-staging";
      repo = "wine-staging";
      rev = "v${version}";
      sha256 = "sha256-2gBfsutKG0ok2ISnnAUhJit7H2TLPDpuP5gvfMVE44o=";
    };
  in
    (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (defaults
      // rec {
        inherit version pname;
        src = fetchFromGitHub {
          owner = "wine-mirror";
          repo = "wine";

          wineRelease = "osu";
          rev = "wine-${version}";
          sha256 = "sha256-uDdjgibNGe8m1EEL7LGIkuFd1UUAFM21OgJpbfiVPJs=";
        };
        patches = ["${nixpkgs-wine}/pkgs/applications/emulators/wine/cert-path.patch"] ++ self.lib.mkPatches ./patches;
      }))
    .overrideDerivation (old: {
      nativeBuildInputs = with pkgs; [autoconf perl hexdump] ++ old.nativeBuildInputs;
      prePatch = ''
        patchShebangs tools
        cp -r ${staging}/patches .
        chmod +w patches
        cd patches
        patchShebangs gitapply.sh
        ./patchinstall.sh DESTDIR="$PWD/.." --all ${lib.concatMapStringsSep " " (ps: "-W ${ps}") []}
        cd ..
      '';
    });
}
