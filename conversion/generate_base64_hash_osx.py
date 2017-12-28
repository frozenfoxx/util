#!/usr/bin/env python2

import sys
from passlib.hash import sha512_crypt

if __name__ == "__main__":
    if len(sys.argv) == 2:
        hash_value = sha512_crypt.encrypt(str(sys.argv[1]))
        print(str(hash_value))
