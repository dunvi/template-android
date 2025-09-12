{
  androidSdk,
  ndkVersion,
}:

# See https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/android-studio/default.nix
# and https://github.com/NixOS/nixpkgs/blob/nixos-unstable/pkgs/applications/editors/android-studio/common.nix
# for the original sources

{
  alsa-lib,
  runtimeShell,
  buildFHSEnv,
  cacert,
  coreutils,
  dbus,
  e2fsprogs,
  expat,
  fetchurl,
  findutils,
  file,
  fontsConf,
  git,
  gnugrep,
  gnused,
  gnutar,
  gtk2,
  glib,
  gzip,
  fontconfig,
  freetype,
  libbsd,
  libpulseaudio,
  libGL,
  libdrm,
  libpng,
  libuuid,
  libsecret,
  libX11,
  libxcb,
  libxkbcommon,
  mesa-demos,
  xcbutilwm,
  xcbutilrenderutil,
  xcbutilkeysyms,
  xcbutilimage,
  xcbutilcursor,
  libxkbfile,
  libXcomposite,
  libXcursor,
  libXdamage,
  libXext,
  libXfixes,
  libXi,
  libXrandr,
  libXrender,
  libXtst,
  makeWrapper,
  ncurses5,
  nspr,
  nss_latest,
  pciutils,
  pkgsi686Linux,
  ps,
  setxkbmap,
  lib,
  stdenv,
  systemd,
  unzip,
  usbutils,
  which,
  runCommand,
  wayland,
  xkeyboard_config,
  xorg,
  zlib,
  makeDesktopItem,
  androidenv,

  forceWayland ? false,
}:

let
  version = "2025.1.3.7"; # "Android Studio Narwhal 3 Feature Drop | 2025.1.3"
  sha256Hash = "sha256-pet3uTmL4pQ/FxB2qKv+IZNx540gMC7hmfOaQ8iLQpQ=";
  channel = "stable";
  pname = "android-studio";

  drvName = "android-studio-${channel}-${version}";
  filename = "android-studio-${version}-linux.tar.gz";

  androidStudio = stdenv.mkDerivation {
    name = "${drvName}-unwrapped";

    src = fetchurl {
      url = "https://dl.google.com/dl/android/studio/ide-zips/${version}/${filename}";
      sha256 = sha256Hash;
    };

    nativeBuildInputs = [
      unzip
      makeWrapper
    ];

    # Causes the shebangs in interpreter scripts deployed to mobile devices to be patched, which Android does not understand
    dontPatchShebangs = true;

    installPhase = ''
      cp -r . $out
      wrapProgram $out/bin/studio \
        --set-default JAVA_HOME "$out/jbr" \
        --set ANDROID_EMULATOR_USE_SYSTEM_LIBS 1 \
        --set QT_XKB_CONFIG_ROOT "${xkeyboard_config}/share/X11/xkb" \
        --set FONTCONFIG_FILE ${fontsConf} \
        --prefix PATH : "${
          lib.makeBinPath [

            # Checked in studio.sh
            coreutils
            findutils
            gnugrep
            which
            gnused

            # For Android emulator
            file
            mesa-demos
            pciutils
            setxkbmap

            # Used during setup wizard
            gnutar
            gzip

            # Runtime stuff
            git
            ps
            usbutils
            libsecret
          ]
        }" \
        --prefix LD_LIBRARY_PATH : "${
          lib.makeLibraryPath [

            # Crash at startup without these
            fontconfig
            freetype
            libXext
            libXi
            libXrender
            libXtst
            libsecret

            # No crash, but attempted to load at startup
            e2fsprogs

            # Gradle wants libstdc++.so.6
            (lib.getLib stdenv.cc.cc)
            # mksdcard wants 32 bit libstdc++.so.6
            pkgsi686Linux.stdenv.cc.cc.lib

            # aapt wants libz.so.1
            zlib
            pkgsi686Linux.zlib
            # Support multiple monitors
            libXrandr

            # For Android emulator
            alsa-lib
            dbus
            expat
            libbsd
            libpulseaudio
            libuuid
            libX11
            libxcb
            libxkbcommon
            xcbutilwm
            xcbutilrenderutil
            xcbutilkeysyms
            xcbutilimage
            xcbutilcursor
            xorg.libICE
            xorg.libSM
            libxkbfile
            libXcomposite
            libXcursor
            libXdamage
            libXfixes
            libGL
            libdrm
            libpng
            nspr
            nss_latest
            systemd

            # For GTKLookAndFeel
            gtk2
            glib

            # For wayland support
            wayland
          ]
        }" \
        ${lib.optionalString forceWayland "--add-flags -Dawt.toolkit.name=WLToolkit"}

      # AS launches LLDBFrontend with a custom LD_LIBRARY_PATH
      wrapProgram $(find $out -name LLDBFrontend) --prefix LD_LIBRARY_PATH : "${
        lib.makeLibraryPath [
          ncurses5
          zlib
        ]
      }"
    '';
    meta.mainProgram = "studio";
  };

  desktopItem = makeDesktopItem {
    name = pname;
    exec = pname;
    icon = pname;
    desktopName = "Android Studio (${channel} channel)";
    comment = "The official Android IDE";
    categories = [
      "Development"
      "IDE"
    ];
    startupNotify = true;
    startupWMClass = "jetbrains-studio";
  };

  # Android Studio downloads prebuilt binaries as part of the SDK. These tools
  # (e.g. `mksdcard`) have `/lib/ld-linux.so.2` set as the interpreter. An FHS
  # environment is used as a work around for that.
  fhsEnv = buildFHSEnv {
    pname = "${drvName}-fhs-env";
    inherit version;
    multiPkgs = pkgs: [
      ncurses5

      # Flutter can only search for certs Fedora-way.
      (runCommand "fedoracert" { } ''
        mkdir -p $out/etc/pki/tls/
        ln -s ${cacert}/etc/ssl/certs $out/etc/pki/tls/certs
      '')
    ];
  };
  mkAndroidStudioWrapper =
    {
      androidStudio,
      androidSdk,
      ndkVersion,
    }:
    runCommand drvName
      {
        startScript =
          let
            androidSdkRoot = "${androidSdk}/libexec/android-sdk";
          in
          ''
            #!${runtimeShell}
            echo "=== nixpkgs Android Studio wrapper" >&2

            ANDROID_SDK_ROOT="${androidSdkRoot}"

            if [ -d "$ANDROID_SDK_ROOT" ]; then
              export ANDROID_SDK_ROOT
              export ANDROID_HOME="$ANDROID_SDK_ROOT"
              echo "  - ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT" >&2

              ANDROID_NDK_ROOT="$ANDROID_SDK_ROOT/ndk/${ndkVersion}"

              if [ -d "$ANDROID_NDK_ROOT" ]; then
                export ANDROID_NDK_ROOT
                echo "  - ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT" >&2
              else
                unset ANDROID_NDK_ROOT
              fi
            else
              unset ANDROID_SDK_ROOT
              unset ANDROID_HOME
            fi
            exec ${fhsEnv}/bin/${drvName}-fhs-env ${lib.getExe androidStudio} "$@"
          '';

        preferLocalBuild = true;
        allowSubstitutes = false;
        passthru =
          {
            inherit version;
            unwrapped = androidStudio;
            full = mkAndroidStudioWrapper { inherit androidStudio androidSdk ndkVersion; };
            sdk = androidSdk;
          };
        meta = {
          license = with lib.licenses; [
            asl20
            unfree
          ]; # The code is under Apache-2.0, but:
          # If one selects Help -> Licenses in Android Studio, the dialog shows the following:
          # "Android Studio includes proprietary code subject to separate license,
          # including JetBrains CLion(R) (www.jetbrains.com/clion) and IntelliJ(R)
          # IDEA Community Edition (www.jetbrains.com/idea)."
          # Also: For actual development the Android SDK is required and the Google
          # binaries are also distributed as proprietary software (unlike the
          # source-code itself).
          platforms = [ "x86_64-linux" ];
          mainProgram = pname;
          sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
        };
      }
      ''
        mkdir -p $out/{bin,share/pixmaps}

        echo -n "$startScript" > $out/bin/${pname}
        chmod +x $out/bin/${pname}

        ln -s ${androidStudio}/bin/studio.png $out/share/pixmaps/${pname}.png
        ln -s ${desktopItem}/share/applications $out/share/applications
      '';
in
mkAndroidStudioWrapper { inherit androidStudio androidSdk ndkVersion; }
