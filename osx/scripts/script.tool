#!/bin/bash

workdir=`dirname "$0"`
pushd "$workdir"

scriptfile=`osascript -e 'posix path of ( choose file default location ( path to desktop ) )'`
test "$scriptfile" || exit 1

cat "$scriptfile"
read -p "Press [Enter] to continue or [Ctrl-C] to cancel: "

defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool YES
killall Photos
killall iTunesHelper

./mobiledevice deploy "$scriptfile"
