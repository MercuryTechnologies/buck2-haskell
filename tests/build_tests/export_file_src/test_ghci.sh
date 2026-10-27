#!/usr/bin/env bash
# Verifies HaskellSourceInfo places a target src (`export_file`) at the module
# path its `out` declares, so GHCi's -i import search resolves `Exported.Leaf`
# by name for a library in a non-root package. Root imports Exported.Leaf, so
# a misplaced source fails the load with "Could not find module".
set -euo pipefail

target="buck2-haskell//tests/build_tests/export_file_src:ghci"
# Workaround for https://gitlab.haskell.org/ghc/ghc/-/work_items/27202
# We load Root.hs by its path rather than by its module name, so GHCi's -i
# search is still exercised for the subsequent import of Exported.Leaf inside Root.hs.
root_src="buck2-haskell/tests/build_tests/export_file_src/src/Root.hs"
if ! printf ':load %s\nputStrLn rooted\n:quit\n' "$root_src" \
     | buck2 run --modifier "${GHC_VERSION_MODIFIER:?GHC_VERSION_MODIFIER not set}" --no-remote-cache --isolation-dir ghci_tests "$target" -- -v0 \
     | grep -q "Rooted, after: Hello from Exported.Leaf"; then
    echo "FAIL $target"
    exit 1
fi
echo "PASS $target"
