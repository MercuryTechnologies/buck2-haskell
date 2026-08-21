load("@buck2-haskell//:defs.bzl", "haskell_binary")
load("@buck2-haskell//:worker_config.bzl", "worker_enabled", "worker_per_configuration")

def _split_configuration(platform: PlatformInfo, refs: struct) -> dict[str, PlatformInfo]:
    configurations = {}
    for name, constraint in [
        ("first", refs.first[ConstraintValueInfo]),
        ("second", refs.second[ConstraintValueInfo]),
    ]:
        configuration = platform.configuration.copy()
        configuration.insert(constraint)
        configurations[name] = PlatformInfo(
            label = "<worker-configuration-test-{}>".format(name),
            configuration = configuration,
        )
    return configurations

_two_configurations = transition(
    impl = _split_configuration,
    refs = {
        "first": "buck2-haskell//tests/build_tests/worker/configurations:worker_configuration_first",
        "second": "buck2-haskell//tests/build_tests/worker/configurations:worker_configuration_second",
    },
    split = True,
)

def _configuration_graph_impl(ctx: AnalysisContext) -> list[Provider]:
    _ = ctx
    return [DefaultInfo()]

_configuration_graph = rule(
    impl = _configuration_graph_impl,
    attrs = {
        "binary": attrs.split_transition_dep(cfg = _two_configurations),
    },
)

def _worker_configuration_test_impl(ctx: AnalysisContext) -> list[Provider]:
    per_configuration = worker_per_configuration()
    expected_worker_count = 2 if per_configuration else 1
    if len(ctx.attrs.workers) != expected_worker_count:
        fail("expected {} configured persistent worker(s), got {}: {}".format(
            expected_worker_count,
            len(ctx.attrs.workers),
            [worker.label for worker in ctx.attrs.workers],
        ))

    if len(ctx.attrs.binaries) != 2:
        fail("expected two configured binaries, got {}: {}".format(
            len(ctx.attrs.binaries),
            [binary.label for binary in ctx.attrs.binaries],
        ))

    # Building both configurations is only sound when they have separate GHC
    # workers. The opt-out is intentionally allowed to share compiler state.
    binaries_to_run = ctx.attrs.binaries if per_configuration else ctx.attrs.binaries[:1]
    binary_executables = []
    for binary in binaries_to_run:
        outputs = binary[DefaultInfo].default_outputs
        if len(outputs) == 0:
            fail("configured binary has no default output: {}".format(binary.label))
        binary_executables.append(outputs[0])

    test_script = ctx.actions.write(
        "worker_configuration_test",
        "#!/bin/sh\nset -eu\nfor binary in \"$@\"; do\n  \"$binary\"\ndone\n",
        is_executable = True,
    )
    return [
        DefaultInfo(default_output = test_script),
        ExternalRunnerTestInfo(
            type = "custom",
            command = [test_script] + binary_executables,
        ),
    ]

_worker_configuration_test = rule(
    impl = _worker_configuration_test_impl,
    attrs = {
        "binaries": attrs.query(),
        "workers": attrs.query(),
    },
)

def worker_configuration_test(name: str, binary_name: str, srcs: list[str], deps: list[str], **kwargs):
    if not worker_enabled():
        return

    haskell_binary(
        name = binary_name,
        srcs = srcs,
        deps = deps,
        _worker = "toolchains//:persistent_worker",
    )

    graph = name + "_graph"
    _configuration_graph(
        name = graph,
        binary = ":" + binary_name,
    )
    _worker_configuration_test(
        name = name,
        binaries = 'kind("haskell_binary", deps(":{}", 1))'.format(graph),
        workers = 'attrfilter("name", "persistent_worker", deps(":{}"))'.format(graph),
        **kwargs
    )
