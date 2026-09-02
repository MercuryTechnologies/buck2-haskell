# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under both the MIT license found in the
# LICENSE-MIT file in the root directory of this source tree and the Apache
# License, Version 2.0 found in the LICENSE-APACHE file in the root directory
# of this source tree.
load("@prelude//cxx:cxx_context.bzl", "get_cxx_toolchain_info")
load(
    "@prelude//cxx:cxx_toolchain_types.bzl",
    "CxxToolchainInfo",
)
load(
    "@prelude//linking:link_info.bzl",
    "LinkStyle",
    "MergedLinkInfo",
    "get_link_args_for_strategy",
    "map_to_link_infos",
    "to_link_strategy",
)
load("@prelude//utils:arglike.bzl", "ArgLike")
load("@prelude//utils:utils.bzl", "dedupe_by_value", "flatten")
load(
    ":library_info.bzl",
    "HaskellLibraryInfo",
    "HaskellLibraryInfoTSet",
)
load(":toolchain.bzl", "HaskellToolchainLibrary")

ExtraLibrariesTSet = transitive_set()

# A list of `HaskellLibraryInfo`s.
HaskellLinkInfo = provider(
    # Contains a list of HaskellLibraryInfo records.
    fields = {
        "info": provider_field(dict[LinkStyle, HaskellLibraryInfoTSet]),
        "prof_info": provider_field(dict[LinkStyle, HaskellLibraryInfoTSet]),
        "extra": provider_field(dict[LinkStyle, list[Artifact]]),
        "extra_libraries": provider_field(ExtraLibrariesTSet),
    },
)

def make_extra_libraries_tset(
        actions: AnalysisActions,
        extra_libraries: list[Dependency],
        haskell_libraries: list[HaskellLinkInfo]) -> ExtraLibrariesTSet:
    return actions.tset(
        ExtraLibrariesTSet,
        value = extra_libraries,
        children = [library.extra_libraries for library in haskell_libraries],
    )

def traverse_extra_libraries(extra_libraries: ExtraLibrariesTSet) -> list[Dependency]:
    return dedupe_by_value(flatten(list(extra_libraries.traverse())))

# A record of a Haskell link group info
HaskellLinkGroupInfo = record(
    # The Haskell link group package name
    pkgname = str,
    # The Haskell link group db artifact
    db = Artifact,
    # The resultant Haskell link group library
    lib = Artifact,
    # Component libraries
    libraries = list[HaskellLibraryInfo],
)

# Provider for HaskellLinkGroup information
HaskellLinkGroupProvider = provider(
    fields = {
        "link_group": provider_field(dict[LinkStyle, HaskellLinkGroupInfo]),
    },
)

def _project_as_package_db(lg: HaskellLinkGroupInfo) -> cmd_args:
    return cmd_args(lg.db)

def _project_as_package(lg: HaskellLinkGroupInfo) -> cmd_args:
    return cmd_args(lg.pkgname, hidden = [lg.lib])

def _get_link_group_deps(children: list[list[str]], lg: HaskellLinkGroupInfo | None) -> list[str]:
    flatted = flatten(children)
    if lg:
        flatted.append(lg.pkgname)
    return flatted

def _get_components(children: list[list[str]], lg: HaskellLinkGroupInfo | None) -> list[str]:
    flatted = flatten(children)
    if lg:
        libs = [ l.name for l in lg.libraries ]
        flatted.extend(libs)
    return flatted

def _get_toolchain_packages(
        children: list[list[HaskellToolchainLibrary]],
        lg: HaskellLinkGroupInfo | None) -> list[HaskellToolchainLibrary]:
    flatted = flatten(children)
    if lg:
        libs = [p for l in lg.libraries for p in l.toolchain_dependencies]
        flatted.extend(libs)
    return dedupe(flatted)

HaskellLinkGroupTSet = transitive_set(
    args_projections = {
        "package_db": _project_as_package_db,
        "package": _project_as_package,
    },
    reductions = {
        "link_group_deps": _get_link_group_deps,
        "components": _get_components,
        "toolchain_packages": _get_toolchain_packages,
    },
)

HaskellLinkGroupTSetProvider = provider(
    fields = {
        "link_group_tsets": provider_field(dict[LinkStyle, HaskellLinkGroupTSet]),
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

def get_link_infos_from_extra_lib_info(actions, label, linker_info, link_style, extra_lib_info):
    link_infos = map_to_link_infos([
        get_link_args_for_strategy(
            actions,
            label,
            linker_info,
            [
                lib[MergedLinkInfo]
                for lib in extra_lib_info.as_deps
            ],
            to_link_strategy(link_style),
            prefer_stripped = True,
            transformation_spec_context = None,
        ),
    ])
    return link_infos