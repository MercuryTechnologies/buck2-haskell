load(
    ":toolchain.bzl",
    "HaskellToolchainInfo",
)
load(":worker_config.bzl", "worker_per_configuration")

def _persistent_worker_impl(ctx: AnalysisContext) -> list[Provider]:
    worker = ctx.attrs.worker[RunInfo]  #haskell_toolchain.worker
    worker_proxy = ctx.attrs.worker_proxy[RunInfo]  # haskell_toolchain.worker_proxy

    cmd = cmd_args(worker_proxy, "--exe", worker)
    cmd.add(ctx.attrs.proxy_args)
    if worker_per_configuration():
        # buck-proxy otherwise routes every Buck worker to its default
        # "singleton" GHC socket, recombining the configurations downstream.
        configuration_hash = str(ctx.label.configured_target().config()).split("#")[-1]
        cmd.add("--socket-name", configuration_hash)
    cmd.add("--")
    cmd.add(ctx.attrs.worker_args)
    return [DefaultInfo(), WorkerInfo(cmd)]

_shared_persistent_worker = rule(
    impl = _persistent_worker_impl,
    attrs = {
        # This rule is itself an exec dep, so normal deps inherit that platform.
        "worker": attrs.dep(providers = [RunInfo]),
        "worker_proxy": attrs.dep(providers = [RunInfo]),
        "proxy_args": attrs.list(attrs.arg(), default = []),
        "worker_args": attrs.list(attrs.arg(), default = []),
    },
)

_per_configuration_persistent_worker = rule(
    impl = _persistent_worker_impl,
    attrs = {
        # Toolchain deps inherit the consumer's resolved execution platform,
        # so these do not perform an independent nested resolution.
        "worker": attrs.exec_dep(providers = [RunInfo]),
        "worker_proxy": attrs.exec_dep(providers = [RunInfo]),
        "proxy_args": attrs.list(attrs.arg(), default = []),
        "worker_args": attrs.list(attrs.arg(), default = []),
    },
    is_toolchain_rule = True,
)

def persistent_worker(**kwargs):
    if worker_per_configuration():
        _per_configuration_persistent_worker(**kwargs)
    else:
        _shared_persistent_worker(**kwargs)
