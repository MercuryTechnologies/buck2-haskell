"""
Definitions for test targets with the right default compiler flags.
"""

load("@buck2-haskell//:defs.bzl", "haskell_library", "haskell_test", "haskell_toolchain_library")
load("@buck2-haskell//tests:defs.bzl", "default_ghc_flags")

def _generate_module_prefix():
    path_parts = package_name().split("/")
    module_parts = list(filter(lambda p: not p.islower(), path_parts))
    return ".".join(module_parts)

def buck2_haskell_test(
        name: str,
        srcs = [],
        *args,
        extra_compiler_flags: list[str] = [],
        module_prefix: str | None = None,
        **kwargs):
    print(module_prefix)
    if not module_prefix:
        module_prefix = _generate_module_prefix()

    haskell_test(
        name = name,
        srcs = srcs,
        compiler_flags = default_ghc_flags + extra_compiler_flags,
        strip_prefix = ["tests"],
        module_prefix = module_prefix,
        **kwargs
    )

def buck2_haskell_library(
        name: str,
        srcs = [],
        extra_compiler_flags: list[str] = [],
        module_prefix: str | None = None,
        **kwargs):
    print(module_prefix)
    if not module_prefix:
        module_prefix = _generate_module_prefix()

    haskell_library(
        name = name,
        srcs = srcs,
        compiler_flags = default_ghc_flags + extra_compiler_flags,
        strip_prefix = ["tests"],
        module_prefix = module_prefix,
        **kwargs
    )
