{
  self,
  pins,
  lib,
  build,
  pkgs,
  pkgsCross,
  pkgsi686Linux,
  callPackage,
  fetchFromGitHub,
  replaceVars,
  moltenvk,
  supportFlags,
  overrideCC,
  wrapCCMulti,
  gcc13,
  stdenv,
  wine-mono,
  # inputs,
  # self,
  # pins,
  # lib,
  # build,
  # pkgs,
  # pkgsCross,
  # pkgsi686Linux,
  # callPackage,
  # fetchFromGitHub,
  # replaceVars,
  # moltenvk,
  # supportFlags,
  # overrideCC,
  # wrapCCMulti,
  # gcc13,
  # stdenv,
  # wine-mono,
}: let
  # nixpkgs-wine = builtins.path {
  #   path = pkgs.path;
  #   name = "source";
  #   filter = path: type: let
  #     wineDir = "${pkgs.pathvector}/pkgs/applications/emulators/wine/";
  #   in (
  #     (type == "directory" && (lib.hasPrefix path wineDir))
  #     || (type != "directory" && (lib.hasPrefix wineDir path))
  #   );
  # };
  nixpkgs-wine = pkgs.path;
  defaults = let
    sources = (import "${nixpkgs-wine}/pkgs/applications/emulators/wine/sources.nix" {inherit pkgs;}).unstable;
  in
    supportFlags
    // {
      inherit moltenvk;
      patches = [];
      buildScript = replaceVars "${nixpkgs-wine}/pkgs/applications/emulators/wine/builder-wow.sh" {
        pkgconfig64remove = lib.makeSearchPathOutput "dev" "lib/pkgconfig" [pkgs.glib pkgs.gst_all_1.gstreamer];
      };
      configureFlags = ["--disable-tests"];
      geckos = with sources; [gecko32 gecko64];
      mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc13 mingwW64.buildPackages.gcc13];
      monos = with sources; [mono];
      pkgArches = [pkgs pkgsi686Linux];
      platforms = ["x86_64-linux"];
      stdenv = overrideCC stdenv (wrapCCMulti gcc13);
      # wineRelease = "unstable";
      mainProgram = "wine64";
    };
  # defaults for newer WoW64 builds
  defaultsWow64 = lib.recursiveUpdate defaults {
    buildScript = null;
    configureFlags = ["--disable-tests" "--enable-archs=x86_64,i386"];
    mingwGccs = with pkgsCross; [mingw32.buildPackages.gcc mingwW64.buildPackages.gcc];
    monos = [wine-mono];
    pkgArches = [pkgs];
    inherit stdenv;
    mainProgram = "wine";
  };
  pnameGen = n: n + lib.optionalString (build == "full") "-full";
in {
  wine-ge = (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix" (defaults
    // {
      pname = pnameGen "wine-ge";
      version = pins.proton-wine.branch;
      src = pins.proton-wine;
    }))
    .overrideAttrs (old: {
    meta = old.meta // {passthru.updateScript = ./update-wine-ge.sh;};
  });

  wine-tkg = (callPackage "${nixpkgs-wine}/pkgs/applications/emulators/wine/base.nix"
    (lib.recursiveUpdate defaultsWow64
      rec {
        pname = pnameGen "wine-tkg";
        version = lib.removeSuffix "\n" (lib.removePrefix "Wine version " (builtins.readFile "${src}/VERSION"));
        src = pins.wine-tkg;
      }))
    .overrideDerivation (
    old: {
      postPatch = ''
        # set -x
        sed -i -e 's/-O2/-O2 -march=alderlake -mtune=alderlake -ftree-vectorize -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types -g2 /g' configure
          # export LDFLAGS='-Wl,-O4,--sort-common,--as-needed'
          # export CFLAGS='-O4 -ftree-vectorize -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types'
          # export CXXFLAGS='-O4 -vftree-vectorize -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types'
          # export CPPFLAGS='-O4 -ftree-vectorize -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types'

          # export configureFlagsArray=CXXFLAGS=\"-O4\ -ftree-vectorize\ -Wno-error=implicit-function-declaration\ -Wno-error=incompatible-pointer-types\"

          # set -x
          # printenv
      '';
      # # configureFlags = [''CFLAGS= $CFLAGS''];

      # NIX_CXXFLAGS_COMPILE = ["-O0"];
      NIX_CFLAGS_COMPILE = let
        headers = pkgs.makeLinuxHeaders {
          inherit (pkgs.linuxKernel.kernels.linux_zen) src version patches;
        };
      in [
        "-I${headers}/include"
        "-O2"
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
