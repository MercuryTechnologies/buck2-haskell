"""
Defaults for Haskell compiler flags.
"""

default_extensions = [
    "Haskell2010",
    #
    "BangPatterns",
    "BlockArguments",
    "DataKinds",
    "DefaultSignatures",
    "DeriveAnyClass",
    "DeriveFunctor",
    "DeriveGeneric",
    "DeriveLift",
    "DeriveTraversable",
    "DerivingStrategies",
    "DerivingVia",
    "FlexibleContexts",
    "FlexibleInstances",
    "GADTs",
    "GeneralizedNewtypeDeriving",
    "ImportQualifiedPost",
    "InstanceSigs",
    "LambdaCase",
    "MultiParamTypeClasses",
    "MultiWayIf",
    "NamedFieldPuns",
    "NegativeLiterals",
    "NumericUnderscores",
    "OverloadedLabels",
    "OverloadedStrings",
    "PartialTypeSignatures",
    "PatternSynonyms",
    "RankNTypes",
    "RecordWildCards",
    "RoleAnnotations",
    "ScopedTypeVariables",
    "StandaloneDeriving",
    "TypeApplications",
    "TypeFamilies",
    "UndecidableInstances",
    "ViewPatterns",
    "OverloadedRecordDot",
    "TypeOperators",
    # for some reason this is on by default???! it turns "label" into a reserved word
    "NoForeignFunctionInterface",
]

default_ghc_flags = ["-X" + ext for ext in default_extensions] + [
    # Fully deterministic build
    # TODO: Enforce this at rules level.
    "-fobject-determinism",
    #
    "-Werror",
    "-Weverything",
    "-Wno-missing-exported-signatures",  # missing-exported-signatures turns off the more strict -Wmissing-signatures. See https://ghc.haskell.org/trac/ghc/ticket/14794#ticket
    "-Wno-missing-export-lists",  # Requires explicit export lists for every module, a pain for large modules
    "-Wno-missing-import-lists",  # Requires explicit imports of _every_ function (e.g. '$'); too strict
    "-Wno-missed-specialisations",  # When GHC can't specialize a polymorphic function. No big deal and requires fixing underlying libraries to solve.
    "-Wno-all-missed-specialisations",  # See missed-specialisations
    "-Wno-unsafe",  # Don't use Safe Haskell warnings
    "-Wno-missing-local-signatures",  # Warning for polymorphic local bindings. Don't think this is an issue
    "-Wno-monomorphism-restriction",  # Don't warn if the monomorphism restriction is used
    "-Wno-missing-safe-haskell-mode",  # Cabal isn’t setting this currently (introduced in GHC 8.10)
    "-Wno-unused-packages",  # Some tooling gives this error
    "-Wno-operator-whitespace",  # GHC bug? https://gitlab.haskell.org/ghc/ghc/-/issues/23297
    "-Wno-missing-kind-signatures", # Noisy
    "-fno-warn-ambiguous-fields",  # Combines poorly with DuplicateRecordFields
    "-fwarn-tabs",  # no tabs in source files

    "-fdefer-diagnostics",  # Print diagnostics at the *end* of the build so they're not in 10k lines of junk
    "-fdiagnostics-color=always",  # Enable color

    # Special for buck2-haskell:
    "-Wno-implicit-prelude",  # Implicit prelude is allowed in this repo
    "-Wno-incomplete-uni-patterns",  # It's tests, being able to unwrap stuff easily is helpful
]
