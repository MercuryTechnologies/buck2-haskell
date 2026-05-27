# Unit tests for util.bzl helpers. Tests run at bzl-load time via
# `util_test()`; any failed assertion surfaces as a parse-time error.
# `tests/BUCK` invokes `util_test()` so the assertions run whenever the
# test cell is evaluated.

load("@prelude//:asserts.bzl", "asserts")
load(":util.bzl", "compute_source_module_paths", "strip_source_prefix")

def _fake_src(short_path):
    # Stand-in for an Artifact — compute_source_module_paths only reads
    # `.short_path` and otherwise passes the value through.
    return struct(short_path = short_path)

def _result_paths(result):
    return sorted([p for (p, _) in result])

def _result_map(result):
    return {p: a for (p, a) in result}

def _test_strip_source_prefix():
    asserts.equals(
        "bar/baz.hs",
        strip_source_prefix("foo/bar/baz.hs", ["foo"]),
    )

    # Prefix must be followed by '/'; "foo" doesn't strip from "foobar.hs".
    asserts.equals(
        "foobar.hs",
        strip_source_prefix("foobar.hs", ["foo"]),
    )

    # First matching prefix wins, even when a later (shorter) one would also match.
    asserts.equals(
        "rest.hs",
        strip_source_prefix("a/b/rest.hs", ["a/b", "a"]),
    )

    asserts.equals(
        "b/rest.hs",
        strip_source_prefix("a/b/rest.hs", ["a"]),
    )

    asserts.equals(
        "no/match.hs",
        strip_source_prefix("no/match.hs", []),
    )

def _test_dict_srcs():
    # Dict srcs: keys preserved when nothing to strip; module_prefix ignored.
    r = compute_source_module_paths(
        package = "pkg",
        module_prefix = "ShouldNotAppear",
        strip_prefix = [],
        sources = {"Foo.hs": "ART_FOO", "Foo/Bar.hs": "ART_BAR"},
    )
    asserts.equals(["Foo.hs", "Foo/Bar.hs"], _result_paths(r))
    m = _result_map(r)
    asserts.equals("ART_FOO", m["Foo.hs"])
    asserts.equals("ART_BAR", m["Foo/Bar.hs"])

    # Bare strip_prefix applied to dict keys.
    asserts.equals(
        [("Foo.hs", "ART")],
        compute_source_module_paths(
            package = "",
            module_prefix = None,
            strip_prefix = ["src"],
            sources = {"src/Foo.hs": "ART"},
        ),
    )

    # Package-relative strip wins over bare when both could match.
    # Full strip list is ["pkg/src", "src"]; "pkg/src/Foo.hs" matches the first.
    asserts.equals(
        [("Foo.hs", "ART")],
        compute_source_module_paths(
            package = "pkg",
            module_prefix = None,
            strip_prefix = ["src"],
            sources = {"pkg/src/Foo.hs": "ART"},
        ),
    )

    # Non-Haskell sources filtered (.txt, .hs-boot are not in HASKELL_EXTENSIONS).
    r = compute_source_module_paths(
        package = "",
        module_prefix = None,
        strip_prefix = [],
        sources = {
            "Foo.hs": "HS",
            "Foo.hs-boot": "BOOT",
            "data.txt": "TXT",
            "Lit.lhs": "LHS",
        },
    )
    asserts.equals(["Foo.hs", "Lit.lhs"], _result_paths(r))

def _test_list_srcs_with_module_prefix():
    # Shallow module_prefix: short_paths joined under module_prefix dir.
    r = compute_source_module_paths(
        package = "tests/Resources",
        module_prefix = "Resources",
        strip_prefix = ["tests"],
        sources = [_fake_src("Lib.hs"), _fake_src("Spec.hs")],
    )
    asserts.equals(["Resources/Lib.hs", "Resources/Spec.hs"], _result_paths(r))

    # Deep module_prefix — regression coverage for 8f47eb98 (sub-package at
    # //local-packages/foo/src/Acme/Foo/Bar). Pre-fix, this returned a
    # path under the cell-root package; the in-tree path must instead be
    # module_prefix-rooted so GHCi's -i search resolves the qualified name.
    src = _fake_src("Lib.hs")
    asserts.equals(
        [("Acme/Foo/Bar/Lib.hs", src)],
        compute_source_module_paths(
            package = "local-packages/foo/src/Acme/Foo/Bar",
            module_prefix = "Acme.Foo.Bar",
            strip_prefix = ["src"],
            sources = [src],
        ),
    )

    # strip_prefix applies to short_path before the module_prefix join.
    src = _fake_src("src/Lib.hs")
    asserts.equals(
        [("Acme/Lib.hs", src)],
        compute_source_module_paths(
            package = "pkg",
            module_prefix = "Acme",
            strip_prefix = ["src"],
            sources = [src],
        ),
    )

    # In the module_prefix branch, strip_prefix is applied bare (no package-
    # relative variants) — strip_prefix=["pkg"] does NOT match short_path "Lib.hs".
    src = _fake_src("Lib.hs")
    asserts.equals(
        [("M/Lib.hs", src)],
        compute_source_module_paths(
            package = "pkg",
            module_prefix = "M",
            strip_prefix = ["pkg"],
            sources = [src],
        ),
    )

    # Non-Haskell sources filtered.
    r = compute_source_module_paths(
        package = "",
        module_prefix = "M",
        strip_prefix = [],
        sources = [
            _fake_src("Lib.hs"),
            _fake_src("Lib.hs-boot"),
            _fake_src("data.txt"),
        ],
    )
    asserts.equals(["M/Lib.hs"], _result_paths(r))

def _test_list_srcs_no_module_prefix():
    # Sub-package at //src/App/Foo with bare "src" strip.
    src = _fake_src("Bar.hs")
    asserts.equals(
        [("App/Foo/Bar.hs", src)],
        compute_source_module_paths(
            package = "src/App/Foo",
            module_prefix = None,
            strip_prefix = ["src"],
            sources = [src],
        ),
    )

    # Top-level local-package with glob(["src/**/*.hs"]):
    # package-relative "<pkg>/src" prefix wins over bare "src".
    src = _fake_src("src/Stripped/Lib.hs")
    asserts.equals(
        [("Stripped/Lib.hs", src)],
        compute_source_module_paths(
            package = "local-packages/foo",
            module_prefix = None,
            strip_prefix = ["src"],
            sources = [src],
        ),
    )

    # Empty package, no strip: short_path passes through unchanged.
    src = _fake_src("Foo.hs")
    asserts.equals(
        [("Foo.hs", src)],
        compute_source_module_paths(
            package = "",
            module_prefix = None,
            strip_prefix = [],
            sources = [src],
        ),
    )

    # Empty string module_prefix is falsy — falls into the no-prefix branch.
    src = _fake_src("Foo.hs")
    asserts.equals(
        [("pkg/Foo.hs", src)],
        compute_source_module_paths(
            package = "pkg",
            module_prefix = "",
            strip_prefix = [],
            sources = [src],
        ),
    )

    # Non-Haskell sources filtered.
    r = compute_source_module_paths(
        package = "",
        module_prefix = None,
        strip_prefix = [],
        sources = [
            _fake_src("Lib.hs"),
            _fake_src("Lib.hs-boot"),
            _fake_src("data.txt"),
        ],
    )
    asserts.equals(["Lib.hs"], _result_paths(r))

def util_test():
    _test_strip_source_prefix()
    _test_dict_srcs()
    _test_list_srcs_with_module_prefix()
    _test_list_srcs_no_module_prefix()
