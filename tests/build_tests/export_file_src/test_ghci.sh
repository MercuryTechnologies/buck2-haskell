#!/usr/bin/env bash
# Verifies HaskellSourceInfo places a target src (`export_file`) at the module
# path its `out` declares, so GHCi's -i import search resolves `Exported.Leaf`
# by name for a library in a non-root package. `:load Root` is what exercises
# it: Root imports Exported.Leaf, so a misplaced source fails the load with
# "Could not find module".
set -euo pipefail

target="buck2-haskell//tests/build_tests/export_file_src:ghci"
if ! printf ':load Root\nputStrLn rooted\n:quit\n' \
     | buck2 run --no-remote-cache --isolation-dir ghci_tests "$target" -- -v0 \
     | grep -q "Rooted, after: Hello from Exported.Leaf"; then
    echo "FAIL $target"
    exit 1
fi
echo "PASS $target"
