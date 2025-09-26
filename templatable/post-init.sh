#! /usr/bin/env nix-shell
#! nix-shell -i bash -p coreutils
#! nix-shell -I nixpkgs=channel:nixos-unstable

set -euo pipefail

if [ -z "$1" ]; then
    echo "Missing module name. Aborting android post-initialization."
    exit 1
fi

modulelower=$(echo $1 | tr '[:upper:]' '[:lower:]')

# edit in the new module name
sed --in-place -e \
    "s/Templatable/$1/g" \
    $(grep -rl Templatable MyProject)
sed --in-place -e \
    "s/org\.dunvi\.templatable/org\.dunvi\.$modulelower/g" \
    $(grep -rl "org.dunvi.templatable" MyProject)

# unnest the project files
mv MyProject/* .
rm -r MyProject
