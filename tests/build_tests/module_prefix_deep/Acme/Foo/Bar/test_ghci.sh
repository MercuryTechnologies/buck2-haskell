#!/usr/bin/env bash
# Verifies HaskellSourceInfo places deep-prefix sources at their module-path
# location so GHCi's -i import search resolves them.
set -euo pipefail

target="buck2-haskell//tests/build_tests/module_prefix_deep/Acme/Foo/Bar:ghci"
if ! buck2 run --no-remote-cache --isolation-dir ghci_tests "$target" -- \
       -e ':set -v0' \
       -e 'putStrLn Acme.Foo.Bar.Lib.greeting' \
       -e 'putStrLn Acme.Foo.Bar.Other.farewell' \
       | grep -q "Goodbye, after: Hello from Acme.Foo.Bar.Lib"; then
    echo "FAIL $target"
    exit 1
fi
echo "PASS $target"
