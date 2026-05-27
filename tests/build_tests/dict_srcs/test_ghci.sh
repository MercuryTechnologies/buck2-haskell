#!/usr/bin/env bash
# Verifies HaskellSourceInfo uses dict-srcs keys as in-tree paths so GHCi's
# -i import search finds `Dict.Lib` and `Dict.Inner` by name.
set -euo pipefail

target="buck2-haskell//tests/build_tests/dict_srcs:ghci"
if ! buck2 run --no-remote-cache --isolation-dir ghci_tests "$target" -- \
       -e ':set -v0' \
       -e 'putStrLn Dict.Lib.greeting' \
       -e 'putStrLn Dict.Inner.farewell' \
       | grep -q "Goodbye, after: Hello from Dict.Lib"; then
    echo "FAIL $target"
    exit 1
fi
echo "PASS $target"
