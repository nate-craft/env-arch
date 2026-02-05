#!/usr/bin/env sh

ENV="${HOME}/Env"

panic() {
    printf "%s%s%s\n" "$(tput setaf 1)" "$@" "$(tput sgr0)"
    exit 1
}

if ! command -v git > /dev/null; then
    printf "Prompting for root permissions to install git. This is necessary to continue...\n"
    sudo pacman -Syu git || panic "Could not install git"
fi

git clone git@github.com:nate-craft/Environment.git "$ENV" || panic "Could not clone into remote repository"
cd "$ENV" || panic "Could not enter local ${ENV}"
chmod +x -R *.sh || panic "Could not give permissions ot local scripts"
./install.sh 
rm -rf "$ENV" || panic "Was unable to delete local ${ENV} directory"
