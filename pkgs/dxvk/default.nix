{
  lib,
  # Enable an async patch, currently dxvk-gplasync
  withAsync ? true,
  # native inputs:
  meson,
  ninja,
  glslang,
  python3,
  pins,
  glfw,
  pkg-config,
  # cross compile inputs:
  SDL2,
  sdl3,
  windows,
  stdenv,
}: let
  inherit (pins) dxvk dxvk-gplasync;
in
  stdenv.mkDerivation {
    name = "dxvk";
    version = "dev";

    enableParallelBuilding = true;
    separateDebugInfo = true;

    nativeBuildInputs = [
      python3
    ];

    buildInputs =
      lib.optionals stdenv.targetPlatform.isWindows [windows.pthreads]
      ++ lib.optionals stdenv.targetPlatform.isLinux [SDL2 sdl3 glfw];

    postPatch = ''
      patchShebangs ./
    '';

    depsBuildBuild = [
      meson
      pkg-config
      ninja
      glslang
    ];

    patches = lib.optionals withAsync [
      # (dxvk-gplasync + "/patches/dxvk-gplasync-${lib.removePrefix "v" dxvk-gplasync.version}.patch")
      (dxvk-gplasync + "/patches/global-dxvk.conf.patch")
    ];

    mesonFlags = ["--buildtype=release -Dnative_glfw=disabled"];

    src = dxvk;

    meta = with lib; {
      license = licenses.zlib;
      description = " Vulkan-based implementation of D3D9, D3D10 and D3D11 for Linux / Wine";
      homepage = "https://github.com/doitsujin/dxvk";
      maintainers = with lib.maintainers; [LunNova];
      platforms = platforms.linux ++ platforms.windows;
      # GCC <13 ends up with an extra dep on mcfg-thread12
      broken = stdenv.cc.isGNU && lib.versionOlder stdenv.cc.version "13";
    };
  }
