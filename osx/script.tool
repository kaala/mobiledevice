#!/bin/bash

if [[ ! -d "zh_CN.lproj" ]]; then
	mkdir zh_CN.lproj
	echo 'CFBundleDisplayName = "装机工具";' >zh_CN.lproj/InfoPlist.strings
	echo 'generate zh_CN.lproj/InfoPlist.strings'
fi

ROOT=`dirname "$0"`
PATH="$ROOT":$PATH

EXECUTE_FROM_APP_BUNDLE=1
./deviceprepare.tool
