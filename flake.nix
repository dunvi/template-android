{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    #nixpkgs-android = {
    #  url = "github:tadfisher/android-nixpkgs";
    #  inputs.nixpkgs.follows = "nixpkgs";
    #};
    flake-parts.url = "github:hercules-ci/flake-parts";
    devshell.url = "github:numtide/devshell";
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, devshell, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devshell.flakeModule
      ];

      systems = [
        "x86_64-linux"
      ];

      perSystem = { config, system, pkgs, ... }:
      let
        lib = pkgs.lib // builtins;

        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        #googletag = {
        #  "aarch64-darwin" = "arm64-v8a";
        #  "aarch64-linux" = "arm64-v8a";
        #  "x86_64-darwin" = "x86-64";
        #  "x86_64-linux" = "x86-64";
        #}.${system};

        #android-sdk = nixpkgs-android.sdk.${system} (sdkPkgs: with sdkPkgs; [
        #  build-tools-34-0-0
        #  cmdline-tools-latest
        #  emulator
        #  platform-tools
        #  platforms-android-34
        #  sources-android-34

          # It's unhappy that these are strings. callPackage?
          #"system-images-android-34-google-apis-${googletag}"
          #"system-images-android-34-google-apis-playstore-${googletag}"
        #]);

      in
      {
        devshells.default = {
          name = "template-android";

          imports = lib.fileset.toList ./.nix ++
            lib.optional(builtins.pathExists ./devenv.local.nix) ./devenv.local.nix;

          packages = [
            pkgs.android-studio-full
          ];

          # These are getting overwritten by the sdk command.
          # I might need to override that in the sdk function implementation
          # or I might need to force override it somewhere else.
          #env = {
          #  ANDROID_HOME = "$DEVENV_ROOT/asdk";
          #  ANDROID_SDK_ROOT = "$DEVENV_ROOT/asdk";
          #  JAVA_HOME = pkgs.jdk17.home;
          #};

          # these were previously in the below:
          #ln -sfv ${android-sdk}/share/android-sdk/* asdk
          #echo "preparing the android sdk directory"
          #mkdir -p asdk
          #echo "creating required environment variables"
          #export ANDROID_HOME=$DEVENV_ROOT/asdk;
          #export ANDROID_SDK_ROOT=$DEVENV_ROOT/asdk;
          #export JAVA_HOME=${pkgs.jdk17.home};

          enterShell = ''
            echo "welcome to android world, still in progress"

            echo "android home is $ANDROID_HOME"
          '';
        };
      };
    };
}
