## First Time Configuration

1. Initialize the project using the [init-project script](https://github.com/dunvi/homefiles/blob/main/users/l/git/init-project.sh): `init-project <name> android`
    * This project requires fixes to the androidenv and AndroidStudio nix packages. (TODO: verify and provide) Obtaining these fixes and matching the paths is not covered.
1. `cd` into the project and launch the devShell e.g. via `direnv` or similar.
1. Note the ANDROID_SDK_ROOT store path output by the startup script.
1. Launch AndroidStudio.
1. Click through the Android Studio Setup Wizard.
    * It will ask you to install the SDK. Ensure the path displayed shows the nix store path.
    * If YES, continue clicking through. The wizard should automatically skip any downloads.
    * If NO, click "Cancel" and confirm that you wish to exit the wizard. The correct SDK path may still be set.
1. Confirm that the SDK path is correct:
    1. Click "More Actions".
    1. Click "SDK Manager".
    1. Ensure the "Android SDK Location" points to the correct store path.
    1. Close the SDK Manager.
1. You should now be able to open a new or existing projectw ithout errors.

## Troubleshooting

* To get rid of all AndroidStudio settings, delete `~/.config/Google/AndroidStudio*`
