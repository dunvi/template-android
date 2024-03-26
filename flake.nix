{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-android = {
      url = "github:tadfisher/android-nixpkgs";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    devenv.url = "github:cachix/devenv";
  };

  outputs = inputs@{ flake-parts, nixpkgs, nixpkgs-android, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.devenv.flakeModule
      ];

      # Usually I will prefer flakeExposed, but for this
      # usecase we know that the dependencies are funky already.
      systems = [
        "x86_64-linux"

        # supported by tadfisher:
        #"aarch64-darwin"
        #"x86_64-darwin"

        # not supported by tadfisher:
        #"aarch64-linux"
      ];

      perSystem = { system, pkgs, ... }:
      let
        pkgs = import nixpkgs {
          system = "${system}";
          config.allowUnfree = true;
        };

        googletag = {
          "aarch64-darwin" = "arm64-v8a";
          "aarch64-linux" = "arm64-v8a";
          "x86_64-darwin" = "x86-64";
          "x86_64-linux" = "x86-64";
        }.${system};

        android-sdk = nixpkgs-android.sdk.${system} (sdkPkgs: with sdkPkgs; [
          build-tools-34-0-0
          cmdline-tools-latest
          emulator
          platform-tools
          platforms-android-34
          sources-android-34

          # It's unhappy that these are strings. callPackage?
          #"system-images-android-34-google-apis-${googletag}"
          #"system-images-android-34-google-apis-playstore-${googletag}"
        ]);

      in
      {
        devenv.shells.default = {
          name = "template-android";

          packages = [
            pkgs.gradle
            pkgs.jdk17

            android-sdk

            # This may only be packaged for x86 right now...
            pkgs.androidStudioPackages.stable
          ];

          # These are getting overwritten by the sdk command.
          # I might need to override that in the sdk function implementation
          # or I might need to force override it somewhere else.
          #env.ANDROID_HOME = "$DEVENV_ROOT/asdk";
          #env.ANDROID_SDK_ROOT = "$DEVENV_ROOT/asdk";
          #env.JAVA_HOME = pkgs.jdk17.home;

          enterShell = ''
            echo "welcome to android world, still in progress"

            echo "preparing the android sdk directory"
            mkdir -p asdk
            ln -sfv ${android-sdk}/share/android-sdk/* asdk

            echo "creating required environment variables"
            export ANDROID_HOME=$DEVENV_ROOT/asdk;
            export ANDROID_SDK_ROOT=$DEVENV_ROOT/asdk;
            export JAVA_HOME=${pkgs.jdk17.home};

            echo "android home is $ANDROID_HOME"
          '';
        };
      };
    };
}
