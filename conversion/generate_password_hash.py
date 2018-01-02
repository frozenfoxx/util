#!/usr/bin/env python3

import sys
import crypt

if __name__ == "__main__":
    if len(sys.argv) == 2:
        hash = crypt.crypt(str(sys.argv[1]), crypt.mksalt(crypt.METHOD_SHA512))
        print(str(hash))
