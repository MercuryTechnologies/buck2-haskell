#!/usr/bin/env python3
"""Compute GHC -package flags for haskell_ghci_global with automatic thinning.

Reads .conf files from materialized package db paths to determine which modules
each package exposes (including re-exports), then emits -package flags with GHC
thinning syntax to resolve module conflicts between priority pairs.

Usage:
  compute_exposed_packages.py
    --pkgdbs-forced=<dir>        symlinked dir mapping pkg name -> nix output
    --exposed-packages=<json>    JSON array of package names to expose
    --thin-pairs=<json>          JSON array of [thin_pkg, preferred_pkg] pairs
    --output=<path>              output file for -package flags (one per line)
"""

import argparse
import glob
import json
import os
import sys
import re


def get_visible_modules(conf_path):
    """Return set of module names visible from a package (from exposed-modules field).

    Handles both owned modules (plain ModuleName) and re-exported ones
    (ModuleName from "pkgid:OrigName") by skipping the "from" keyword and
    any token containing a colon.
    """
    modules = set()
    with open(conf_path) as f:
        lines = f.readlines()

    in_field = False
    for line in lines:
        if line.startswith("exposed-modules:"):
            in_field = True
            rest = line[len("exposed-modules:"):].strip()
        elif in_field and line[:1] in (" ", "\t"):
            rest = line.strip()
        else:
            in_field = False
            rest = ""

        if rest:
            for tok in rest.replace(",", " ").split():
                tok = tok.strip()
                if not tok or tok == "from" or ":" in tok:
                    continue
                if tok[:1].isupper():
                    modules.add(tok)

    return modules


_CONF_NAME_RE = re.compile(r"^(?P<name>.+)-\d[\w.\-]*\.conf$")


def _basename_matches_pkg(path, pkg_name):
    """Confirm a .conf path's basename is for `pkg_name` (i.e. <pkg_name>-<version>.conf).

    Avoids picking up sibling-package .confs (e.g. transitively-registered deps
    bundled in the same package.conf.d) that happen to live under <pkg_name>/.
    """
    base = os.path.basename(path)
    m = _CONF_NAME_RE.match(base)
    return m is not None and m.group("name") == pkg_name


def find_conf(pkgdbs_forced, pkg_name):
    """Find the .conf file for `pkg_name` in the forced pkgdbs directory.

    Returns None if no match is found; caller is expected to warn.
    """
    pattern = os.path.join(pkgdbs_forced, pkg_name, "**", "*.conf")
    matches = [
        m for m in glob.glob(pattern, recursive=True)
        if "package.conf.d" in m and _basename_matches_pkg(m, pkg_name)
    ]
    if matches:
        return matches[0]
    # Fallback: search all subdirs for a conf matching the package name prefix
    pattern2 = os.path.join(pkgdbs_forced, "**", "package.conf.d", pkg_name + "-*.conf")
    matches2 = [
        m for m in glob.glob(pattern2, recursive=True)
        if _basename_matches_pkg(m, pkg_name)
    ]
    return matches2[0] if matches2 else None


def main():
    p = argparse.ArgumentParser(fromfile_prefix_chars="@")
    p.add_argument("--pkgdbs-forced", required=True)
    p.add_argument("--exposed-packages", required=True)
    p.add_argument("--thin-pairs", required=True)
    p.add_argument("--output", required=True)
    args = p.parse_args()

    exposed = json.loads(args.exposed_packages)
    thin_pairs = {thin: preferred for thin, preferred in json.loads(args.thin_pairs)}
    exposed_set = set(exposed)

    lines = []
    for pkg in exposed:
        preferred = thin_pairs.get(pkg)
        if preferred and preferred in exposed_set:
            thin_conf = find_conf(args.pkgdbs_forced, pkg)
            pref_conf = find_conf(args.pkgdbs_forced, preferred)
            if thin_conf and pref_conf:
                thin_mods = get_visible_modules(thin_conf)
                pref_mods = get_visible_modules(pref_conf)
                keep = sorted(thin_mods - pref_mods)
                if keep:
                    pkg_spec = "{} ({})".format(pkg, ", ".join(keep))
                    lines.append("-package")
                    lines.append('"{}"'.format(pkg_spec))
                # else: package fully shadowed by preferred, omit it entirely
                continue
            # Fell through: at least one .conf is missing. Warn so the user
            # finds out, instead of silently emitting a non-thinned -package
            # flag that will reproduce the ambiguous-module error thinning
            # was supposed to fix.
            missing = []
            if not thin_conf:
                missing.append(pkg)
            if not pref_conf:
                missing.append(preferred)
            print(
                "compute_exposed_packages: warning: thin_packages pair "
                "({pkg}, {pref}) requested but could not locate .conf for: "
                "{missing} under {pkgdbs}. Falling back to unthinned -package."
                .format(
                    pkg=pkg,
                    pref=preferred,
                    missing=", ".join(missing),
                    pkgdbs=args.pkgdbs_forced,
                ),
                file=sys.stderr,
            )
        lines.append("-package")
        lines.append(pkg)

    with open(args.output, "w") as f:
        f.write("\n".join(lines))


if __name__ == "__main__":
    main()
