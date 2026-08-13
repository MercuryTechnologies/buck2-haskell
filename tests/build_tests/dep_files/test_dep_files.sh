#!/usr/bin/env bash
set -euo pipefail

pkg=buck2-haskell/tests/build_tests/dep_files
target="buck2-haskell//tests/build_tests/dep_files:lib"

backup=$(mktemp -d -p "${BUCK_SCRATCH_PATH:-/tmp}")
cp "$pkg/Dep.hs" "$backup/Dep.hs"
cp "$pkg/Base.hs" "$backup/Base.hs"
cp "$pkg/Orphan/Base.hs" "$backup/OrphanBase.hs"
cp "$pkg/Finst/Inst.hs" "$backup/FinstInst.hs"
trap 'cp "$backup/Dep.hs" "$pkg/Dep.hs"; cp "$backup/Base.hs" "$pkg/Base.hs"; cp "$backup/OrphanBase.hs" "$pkg/Orphan/Base.hs"; cp "$backup/FinstInst.hs" "$pkg/Finst/Inst.hs"; rm -rf "$backup"' EXIT

build() {
    # When using watchman (as buck2-test-suites currently uses), immediately building after file
    # edits can result in no-op builds occasionally.
    sleep 1
    buck2 --isolation-dir dep_files build --no-remote-cache -c ghc-worker.enable=true "$target" > /dev/null
}

compiled() {
    buck2 --isolation-dir dep_files log what-ran |
        grep -qP "haskell_compile_shared $1\)\t(worker|local)\t"
}

named() {
    buck2 --isolation-dir dep_files audit dep-files -c ghc-worker.enable=true "$target" haskell_compile_shared "$1"
}

expect() {
    named "$1" | grep -qE "$2\$" || { echo "FAIL: $1 should key on $2 ($3)"; named "$1"; exit 1; }
}

reject() {
    if named "$1" | grep -qE "$2"; then
        echo "FAIL: $1 should not key on $2 ($3)"
        named "$1"
        exit 1
    fi
}

buck2 --isolation-dir dep_files kill

build
expect User '/Dep\.dyn_hi\.hash' "User depends on Dep's ABI"
reject User '/Dep\.dyn_hi$'      "User does not depend on Dep's dyn_hi"
reject User '/Base\.'            "User does not depend on transitive Base"
expect Dep '/Base\.dyn_hi\.hash' "Dep depends on Base's ABI"
reject Dep '/Base\.dyn_hi$'      "Dep does not depend on Base's dyn_hi"
expect THUser '/Dep\.dyn_hi'  "THUser depends on Dep's dyn_hi"
# Expect to record the transitive usage on Base for THUser's splice.
# Changes to Base's `hello` are not reflected in Dep's interface.
expect THUser '/Base\.dyn_hi' "THUser depends on Base's dyn_hi"

printf '\n-- comment, changing the interface but not the ABI\n' >> "$pkg/Dep.hs"
build
if compiled User; then
    echo "FAIL: User was recompiled even though there was no ABI change"
    exit 1
fi
compiled THUser || { echo "FAIL: THUser was not recompiled, splice output could be stale"; exit 1; }

cp "$backup/Dep.hs" "$pkg/Dep.hs"
build

# Same thing, but for an indirect usage.
printf '\n-- a comment changes the interface but not the ABI\n' >> "$pkg/Base.hs"
build
if compiled User; then
    echo "FAIL: User was recompiled even though there was no ABI change"
    exit 1
fi
if compiled Dep; then
    echo "FAIL: Dep was recompiled even though there was no ABI change"
    exit 1
fi
compiled THUser || { echo "FAIL: THUser was not recompiled, splice output could be stale"; exit 1; }

cp "$backup/Base.hs" "$pkg/Base.hs"
build

sed -i 's|^module Dep (answer, greeting) where$|module Dep (answer, greeting, extra) where|' "$pkg/Dep.hs"
printf '\nextra :: Int\nextra = 1\n' >> "$pkg/Dep.hs"
build
compiled User   || { echo "FAIL: User was not recompiled after changing Dep's ABI."; exit 1; }
compiled THUser || { echo "FAIL: THUser was not recompiled after changing Dep's ABI."; exit 1; }

cp "$backup/Dep.hs" "$pkg/Dep.hs"
build

printf '\ninstance C Int where\n  c n = n\n' >> "$pkg/Orphan/Base.hs"
build
compiled Orphan.Dep  || { echo "FAIL: Orphan.Dep was not recompiled after adding an orphan instance to Orphan.Base."; exit 1; }
compiled Orphan.User || { echo "FAIL: Orphan.User was not recompiled after adding an orphan instance below Orphan.Dep."; exit 1; }

sed -i 's|^type instance F T = Int$|type instance F T = Integer|' "$pkg/Finst/Inst.hs"
build
compiled Finst.Inst || { echo "FAIL: Finst.Inst was not recompiled."; exit 1; }
compiled Finst.User || { echo "FAIL: Finst.Dep's ABI does not change but we should still recompile Finst.User."; exit 1; }

echo "PASS $target"
