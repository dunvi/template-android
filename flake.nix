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

        sdkRoot = "${pkgs.androidenv.androidPkgs.androidsdk}/libexec/android-sdk";

      in
      {
        devShells.default = pkgs.mkShell {
          name = "template-android";

          imports = [] ++
            lib.optional(builtins.pathExists ./devenv.local.nix)
              ./devenv.local.nix;

          buildInputs = [
            pkgs.android-studio-full
          ];

          ANDROID_HOME="${sdkRoot}";
          ANDROID_SDK_ROOT="${sdkRoot}";
          ANDROID_NDK_ROOT="${sdkRoot}/ndk-bundle";

          shellHook = ''
            echo "welcome to android world, still in progress"
            echo "ANDROID_HOME=$ANDROID_HOME"
            echo "ANDROID_SDK_ROOT=$ANDROID_SDK_ROOT"
            echo "ANDROID_NDK_ROOT=$ANDROID_NDK_ROOT"
          '';
        };
      };
    };
}
