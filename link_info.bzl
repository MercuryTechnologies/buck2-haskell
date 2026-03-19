# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under both the MIT license found in the
# LICENSE-MIT file in the root directory of this source tree and the Apache
# License, Version 2.0 found in the LICENSE-APACHE file in the root directory
# of this source tree.

load(
    "@prelude//cxx:cxx_toolchain_types.bzl",
    "CxxToolchainInfo",
)
load(
    "@prelude//linking:link_info.bzl",
    "LinkStyle",
)
load("@prelude//utils:arglike.bzl", "ArgLike")
load("@prelude//utils:utils.bzl", "flatten")
load(
    ":library_info.bzl",
    "HaskellLibraryInfo",
    "HaskellLibraryInfoTSet",
)

# A list of `HaskellLibraryInfo`s.
HaskellLinkInfo = provider(
    # Contains a list of HaskellLibraryInfo records.
    fields = {
        "info": provider_field(dict[LinkStyle, HaskellLibraryInfoTSet]),
        "prof_info": provider_field(dict[LinkStyle, HaskellLibraryInfoTSet]),
        "extra": provider_field(dict[LinkStyle, list[Artifact]]),
    },
)

# HaskellProfLinkInfo exposes the MergedLinkInfo of a target and all of its
# dependencies built for profiling. This allows top-level targets (e.g.
# `haskell_binary`) to be defined with profiling enabled by default.
HaskellProfLinkInfo = provider(
    fields = {
        "prof_infos": provider_field(typing.Any, default = None),  # MergedLinkInfo
    },
)

# Provider for HaskellLinkGroup information

HaskellLinkGroupProvider = provider(
    fields = {
        "pkgname": provider_field(str),
        "db": provider_field(Artifact),
        "lib": provider_field(Artifact),
        "libraries": provider_field(list[HaskellLibraryInfo]),
    },
)

def _project_as_package_db(lg: HaskellLinkGroupProvider) -> cmd_args:
    return cmd_args(lg.db)

def _project_as_package(lg: HaskellLinkGroupProvider) -> cmd_args:
    return cmd_args(lg.pkgname, hidden = [lg.lib])

def _get_link_group_deps(children: list[list[str]], lg: HaskellLinkGroupProvider | None) -> list[str]:
    flatted = flatten(children)
    if lg:
        flatted.append(lg.pkgname)
    return flatted

def _get_components(children: list[list[str]], lg: HaskellLinkGroupProvider | None) -> list[str]:
    flatted = flatten(children)
    if lg:
        libs = [ l.name for l in lg.libraries ]
        flatted.extend(libs)
    return flatted

HaskellLinkGroupTSet = transitive_set(
    args_projections = {
        "package_db": _project_as_package_db,
        "package": _project_as_package,
    },
    reductions = {
        "link_group_deps": _get_link_group_deps,
        "components": _get_components,
    },
)

HaskellLinkGroupTSetProvider = provider(
    fields = {
        "link_group_tsets": provider_field(HaskellLinkGroupTSet),
    },
)

def cxx_toolchain_link_style(ctx: AnalysisContext) -> LinkStyle:
    return ctx.attrs._cxx_toolchain[CxxToolchainInfo].linker_info.link_style

def attr_link_style(ctx: AnalysisContext) -> LinkStyle:
    if ctx.attrs.link_style != None:
        return LinkStyle(ctx.attrs.link_style)
    else:
        return cxx_toolchain_link_style(ctx)

# External linkable taylored for GHC-as-a-linker. This is needed because some linker
# options cannot be passed directly to GHC as a linker.
ExtraGhcLinkerFlagsInfo = provider(fields = {
    "flags": list[ArgLike],
})

GhcLinkableInfo = provider(fields = {
    "extra_ghc_linker_flags_dynamic": DynamicValue,
})
