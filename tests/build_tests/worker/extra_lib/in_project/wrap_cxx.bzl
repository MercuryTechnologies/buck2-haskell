load("@prelude//linking:link_info.bzl", "MergedLinkInfo")
load(
    "@buck2-haskell//:link_info.bzl",
    "ExtraGhcLinkerFlagsInfo",
    "GhcLinkableInfo",
)

def _dummy_impl(actions: AnalysisActions):
    # NOTE: empty flag list gives an error.
    # TODO (wavewave): should be able to use empty.
    return [ExtraGhcLinkerFlagsInfo(flags = ["-v"])]

_dummy = dynamic_actions(impl = _dummy_impl, attrs = {})

def _wrap_cxx_impl(ctx: AnalysisContext) -> list[Provider]:
    if ctx.attrs.wrapped.get(MergedLinkInfo):
        providers = [
            DefaultInfo(),
            ctx.attrs.wrapped[MergedLinkInfo],
        ]
        dyn = ctx.actions.dynamic_output_new(_dummy())
        providers.append(GhcLinkableInfo(extra_ghc_linker_flags_dynamic = dyn))
        return providers
    else:
        fail("No MergedLinkInfo from wrapped native lib")

wrap_cxx = rule(
    impl = _wrap_cxx_impl,
    attrs = {
        "wrapped": attrs.dep(),
    },
)
