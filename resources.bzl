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
        # a resource is either an Artifact, or a Dependency
        # e.g.
        #   "config/file.txt" <= source file in the same package
        #   "//some/package:target" <= target reference in a different package
        #
        #
        pkg = ctx.label.package if isinstance(resource, Artifact) else resource.label.package

        resources[paths.join(pkg, name)] = single_artifact(resource)

    return resources
