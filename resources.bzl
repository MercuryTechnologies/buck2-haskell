load(
    "@prelude//:artifacts.bzl",
    "ArtifactOutputs",  # @unused Used as a type
    "single_artifact",
)
load("@prelude//:paths.bzl", "paths")
load("@prelude//utils:utils.bzl", "from_named_set")

def haskell_attr_resources(ctx: AnalysisContext) -> dict[str, ArtifactOutputs]:
    """
    Return the resources provided by this rule, as a map of resource name to
    a tuple of the resource artifact and any "other" outputs exposed by it.
    """
    resources = {}

    for name, resource in from_named_set(ctx.attrs.resources).items():
        resources[paths.join(ctx.label.package, name)] = single_artifact(resource)

    return resources
