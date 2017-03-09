#!/usr/bin/env bash

set -e

PACKAGE=$1

if [ -z "$PACKAGE" ]; then
	echo '[-] No package specified'
	exit
fi

echo "[+] Backing up $PACKAGE data..."
adb backup -f "$PACKAGE".DATA.ab $PACKAGE

echo "[+] Backing up $PACKAGE APK..."
adb backup -apk -f "$PACKAGE".APK.ab $PACKAGE

echo "[+] Extracting APK..."
java -jar abe-all.jar unpack "$PACKAGE".APK.ab "$PACKAGE".APK.ab.tar
rm "$PACKAGE".APK.ab
APK_FILENAME=$(basename $(tar tf "$PACKAGE".APK.ab.tar | grep '^apps/'"$PACKAGE"'/a/'))
tar xvf "$PACKAGE".APK.ab.tar -C ./ "apps/$PACKAGE/a/$APK_FILENAME" --strip-components=3
mv "$APK_FILENAME" "$PACKAGE".apk
rm "$PACKAGE".APK.ab.tar

echo
echo "[+] Done"
