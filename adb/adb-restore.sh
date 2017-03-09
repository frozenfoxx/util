#!/bin/bash

set -e

PACKAGE=$1

if [ -z "$PACKAGE" ]; then
	echo '[-] No package specified'
	exit
fi

echo "[+] Installing $PACKAGE APK..."
adb install -r $PACKAGE.apk

echo "[+] Restoring $PACKAGE data..."
adb restore $PACKAGE.DATA.ab

echo
echo "[+] Done"
