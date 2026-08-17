def worker_enabled() -> bool:
    value = read_root_config("ghc-worker", "enable", "false").lower()
    return value in ["true", "yes", "on"]

def worker_per_configuration() -> bool:
    value = read_root_config("ghc-worker", "per_configuration", "true").lower()
    if value == "true":
        return True
    if value == "false":
        return False
    fail("ghc-worker.per_configuration must be `true` or `false`, got `{}`".format(value))
