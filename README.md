## First Time Configuration

###  Initialize a project from the template
https://github.com/dunvi/homefiles/blob/main/users/l/git/init-project.sh

* Create your destination project directory
* For each of the items in `./templatable/files.txt`, copy it to the destination project:
```
while read file ; do cp -R $file <destination>/$file done < $(curl -L https://github.com/dunvi/template-android/blob/main/templatable/files.txt)
```
* Run the post-init script:
```
curl -L https://github.com/dunvi/template-android/blob/main/templatable/post-init.sh | bash -s PROJECT_NAME android
```
* Initialize the directory as a git repository:
```
git init
```

### First time AndroidStudio launch

1. `cd` into the project and launch the devShell e.g. via `direnv` or similar. This will probably take a bit to build.
1. Note the ANDROID_SDK_ROOT store path output by the shell when loaded.
1. Launch AndroidStudio: `android-studio`
1. Click _through_ the Android Studio Setup Wizard.
    * It will ask you to install the SDK. Ensure the path displayed shows the nix store path.
    * If YES, continue clicking through. The wizard should automatically skip any downloads.
    * If NO, click "Cancel" and confirm that you wish to exit the wizard. The correct SDK path may still be set, see the next step.
1. Confirm that the SDK path is correct:
    1. Click "More Actions".
    1. Click "SDK Manager".
    1. Ensure the "Android SDK Location" points to the correct store path.
    1. Close the SDK Manager.

1. You should now be able to open a new or existing project without errors.

## Troubleshooting

* To get rid of all AndroidStudio settings, delete `~/.config/Google/AndroidStudio*`
