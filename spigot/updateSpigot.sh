#!/usr/bin/env bash

echo "[+] Changing directories..."
cd ${HOME}/build

echo "[+] Downloading latest BuildTools.jar..."
wget -O BuildTools.jar https://hub.spigotmc.org/jenkins/job/BuildTools/lastSuccessfulBuild/artifact/target/BuildTools.jar

echo "[+] Configuring git..."
git config --global --unset core.autocrlf

echo "[+] Building Spigot..."
java -jar BuildTools.jar

echo "[+] Changing back to ${HOME}..."
cd ${HOME}

echo "[+] Moving build artifacts..."
mv ${HOME}/build/craftbukkit-*.jar ${HOME}/
mv ${HOME}/build/spigot-*.jar ${HOME}/

echo "[+] Building symlinks..."
if [ -f ${HOME}/craftbukkit-latest.jar ]; then
	  rm ${HOME}/craftbukkit-latest.jar
  fi

  if [ -f ${HOME}/spigot-latest.jar ]; then
	    rm ${HOME}/spigot-latest.jar
    fi

    ln -s $(ls -t ${HOME}/craftbukkit-* | head -1) ${HOME}/craftbukkit-latest.jar
    ln -s $(ls -t ${HOME}/spigot-* | head -1) ${HOME}/spigot-latest.jar

    echo "[+] Restarting server..."
    java -Xms512M -Xmx512M -XX:+UseConcMarkSweepGC -jar ${HOME}/spigot-latest.jar
