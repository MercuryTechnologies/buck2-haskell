#!/usr/bin/env bash
# Verifies HaskellSourceInfo strips the `src` prefix from glob'd sources so
# GHCi's -i import search finds `Stripped.Lib` and `Stripped.Inner` by name.
set -euo pipefail

target="buck2-haskell//tests/build_tests/strip_prefix_glob:ghci"
if ! buck2 run --no-remote-cache --isolation-dir ghci_tests "$target" -- \
       -e ':set -v0' \
       -e 'putStrLn Stripped.Lib.greeting' \
       -e 'putStrLn Stripped.Inner.farewell' \
       | grep -q "Goodbye, after: Hello from Stripped.Lib"; then
    echo "FAIL $target"
    exit 1
fi
echo "PASS $target"
