#!/usr/bin/env python3

"""Wrapper script for calling `ghc` as a linker driver.

`ghc` as a linker driver takes some `ghc`-specific arguments (`-package`,
`-package-db`, `-threaded`), uses _some_ linker arguments (`-shared`,
`puppy.dylib`, `-l`, `-L`), and ignores _some_ linker arguments (`-Wl`).

For `ghc` to pass linker arguments through to `cc` (which passes them through
to the linker itself), we need to prefix them with `-optl`. However, we get
linker arguments from a variety of sources (the `linker_flags` attr on rules,
common functions in the prelude, etc.), and they contain a mix of kinds of
arguments.

Therefore, because `cmd_args` can't be filtered or inspected after being
created, we need to use a wrapper script to prefix linker arguments correctly
before passing them to `ghc`.
"""

import argparse
from pathlib import Path
import subprocess
import sys


def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__, add_help=False, fromfile_prefix_chars="@"
    )
    parser.add_argument(
        "--ghc", required=True, type=Path, help="Path to the Haskell linker GHC."
    )
    parser.add_argument(
        "--argfile-out",
        required=True,
        type=Path,
        help="""
        This script needs to process the arguments it receives in order to
        prefix pass-through linker arguments with `-optl`, which requires
        writing a second argfile.

        In order to make this argfile accessible for debugging after the
        wrapper script exits, the user must pass in an output path where the
        argfile will be written.
        """,
    )
    args, ghc_args = parser.parse_known_args()

    ghc: Path = args.ghc
    argfile_out: Path = args.argfile_out

    processed_ghc_args = []
    for ghc_arg in ghc_args:
        # TODO: Are there other args that need the `-optl` treatment?
        if ghc_arg.startswith("-Wl"):
            processed_ghc_args.append(f"-optl{ghc_arg}")
        elif ghc_arg == "+RTS":
            # RTS arguments can't be passed in argfiles but I don't think we
            # should receive them when linking...
            raise ValueError(
                "`ghc_linker_wrapper.py` does not expect to receive RTS args!"
            )
        else:
            processed_ghc_args.append(ghc_arg)

    with argfile_out.open("w", encoding="utf-8") as argfile_out_handle:
        # You would THINK that `writelines` is what we want here, but that
        # doesn't bother to add newlines for us!
        argfile_out_handle.write("\n".join(processed_ghc_args))
        argfile_out_handle.write("\n")

    result = subprocess.run([ghc, f"@{argfile_out}"])

    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
