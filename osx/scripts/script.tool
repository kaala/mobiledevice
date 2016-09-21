#!/bin/bash

workdir=`dirname "$0"`
pushd "$workdir"

scriptfile=`osascript -e 'posix path of ( choose file default location ( path to desktop ) )'`
test "$scriptfile" || exit 1

killall iTunesHelper
./mobiledevice deploy dhh.txt
