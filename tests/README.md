# Tests for buck2-haskell

This directory contains tests for buck2-haskell.
They're intended to be run in the context of another repo provisioning a toolchain.

Said toolchain is expected to provide a small set of `haskell_toolchain_library` packages in its package database; see `./BUCK` for a complete list.

## Running tests

Set up buck2-haskell as the cell `buck2-haskell` in a parent Buck2 project with an existing Haskell toolchain at `toolchains//:haskell`.
At some future date, we may ship a toolchain in this repo so this isn't required.

That is, set something like the following in the buckconfig of the parent project:
```
[cells]
buck2-haskell = path/to/buck2-haskell
```

Then:
```
$ buck test buck2-haskell//...
```
