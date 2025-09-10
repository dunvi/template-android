{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {

      systems = [
        "x86_64-linux"
      ];

      perSystem = { config, system, pkgs, ... }:
      let
        lib = pkgs.lib // builtins;

        pkgs = import nixpkgs {
          inherit system;
          config = {
            allowUnfree = true;
            android_sdk.accept_license = true;
          };
        };

        androidBundle = pkgs.androidenv.composeAndroidPackages {
          numLatestPlatformVersions = 2;
          includeEmulator = true;
          includeSystemImages = true;
          includeSources = true;
          includeNDK = true;
        };

        sdkRoot = "${androidBundle.androidsdk}/libexec/android-sdk";

        androidStudio = pkgs.android-studio-full;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "template-android";

          imports = [] ++
            lib.optional(builtins.pathExists ./devenv.local.nix)
              ./devenv.local.nix;

          buildInputs = [
            (androidStudio.withSdk (androidBundle).androidsdk)
            androidBundle.androidsdk
            androidBundle.platform-tools
            pkgs.jdk17
          ];

          ANDROID_HOME="${sdkRoot}";
          ANDROID_SDK_ROOT="${sdkRoot}";
          ANDROID_NDK_ROOT="${sdkRoot}/ndk-bundle";

          JAVA_HOME="${pkgs.jdk17}";
          #GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${sdkRoot}/build-tools/${buildToolsVersion}/aapt2";

          shellHook = ''
            echo "welcome to android world, still in progress"

            echo "ANDROID_HOME=$ANDROID_HOME"
            echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
            echo "ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT"

            adb devices
          '';
        };
      };
    };
}
