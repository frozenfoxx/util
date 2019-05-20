#!/bin/bash

# Dumps Packet Filter rules

function pfprint() {
  if [ -n "$1" ];then
    sudo pfctl -a "$2" -s"$1" 2>/dev/null
  else
    sudo pfctl -s"$1" 2>/dev/null
  fi
}

function print_all() {

  local p=$(printf "%-40s" $1)
  (
    pfprint r "$1" | sed "s,^,r     ,"
    pfprint n "$1" | sed "s,^,n     ,"
    pfprint A "$1" | sed "s,^,A     ,"
  ) | sed "s,^,$p,"

  for a in `pfprint A "$1"`; do
    print_all "$a"
  done
}

print_all
