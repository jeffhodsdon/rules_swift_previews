# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Analysis tests for the source_collector_aspect."""

load("@bazel_skylib//lib:unittest.bzl", "analysistest", "asserts")
load("//internal:core.bzl", "source_collector_aspect")
load("//internal:providers.bzl", "SourceFilesInfo")

# =============================================================================
# Helper rule to apply aspect and capture SourceFilesInfo
# =============================================================================

def _aspect_test_rule_impl(ctx):
    """Rule that applies the source_collector_aspect and stores results."""
    target = ctx.attr.target
    info = target[SourceFilesInfo] if SourceFilesInfo in target else None
    return [
        DefaultInfo(),
        # Pass through the SourceFilesInfo for analysis tests to examine
        info,
    ] if info else [DefaultInfo()]

aspect_test_rule = rule(
    implementation = _aspect_test_rule_impl,
    attrs = {
        "target": attr.label(
            mandatory = True,
            aspects = [source_collector_aspect],
        ),
    },
)

# =============================================================================
# Test: Simple library collects sources
# =============================================================================

def _simple_lib_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    # Check SourceFilesInfo is present
    asserts.true(env, SourceFilesInfo in target)
    info = target[SourceFilesInfo]

    # Check sources are collected
    sources = info.sources.to_list()
    asserts.true(env, len(sources) > 0)

    # Check module_sources has the module
    asserts.true(env, "SimpleLib" in info.module_sources)

    return analysistest.end(env)

simple_lib_test = analysistest.make(_simple_lib_test_impl)

# =============================================================================
# Test: Library with dependency collects transitive sources
# =============================================================================

def _lib_with_deps_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    info = target[SourceFilesInfo]

    # Check both modules are present
    asserts.true(env, "AppLib" in info.module_sources)
    asserts.true(env, "CoreLib" in info.module_sources)

    # Check module_deps tracks the dependency
    asserts.true(env, "AppLib" in info.module_deps)
    app_deps = info.module_deps.get("AppLib", [])
    asserts.true(env, "CoreLib" in app_deps)

    return analysistest.end(env)

lib_with_deps_test = analysistest.make(_lib_with_deps_test_impl)

# =============================================================================
# Test: Custom module name is used
# =============================================================================

def _custom_module_name_test_impl(ctx):
    env = analysistest.begin(ctx)
    target = analysistest.target_under_test(env)

    info = target[SourceFilesInfo]

    # Should use module_name "Utilities" not target name "utils_target"
    asserts.true(env, "Utilities" in info.module_sources)
    asserts.false(env, "utils_target" in info.module_sources)

    return analysistest.end(env)

custom_module_name_test = analysistest.make(_custom_module_name_test_impl)

# =============================================================================
# Test targets setup function
# =============================================================================

def aspect_test_suite(name):
    """Create the test suite for the source_collector_aspect.

    Args:
        name: The name of the test suite
    """

    # Create the test targets that apply the aspect
    aspect_test_rule(
        name = "simple_lib_subject",
        target = "//tests/fixtures:SimpleLib",
        tags = ["manual"],
    )

    aspect_test_rule(
        name = "lib_with_deps_subject",
        target = "//tests/fixtures:AppLib",
        tags = ["manual"],
    )

    aspect_test_rule(
        name = "custom_module_subject",
        target = "//tests/fixtures:utils_target",
        tags = ["manual"],
    )

    # Create the analysis tests
    simple_lib_test(
        name = "simple_lib_test",
        target_under_test = ":simple_lib_subject",
    )

    lib_with_deps_test(
        name = "lib_with_deps_test",
        target_under_test = ":lib_with_deps_subject",
    )

    custom_module_name_test(
        name = "custom_module_name_test",
        target_under_test = ":custom_module_subject",
    )

    # Bundle into a test suite
    native.test_suite(
        name = name,
        tests = [
            ":simple_lib_test",
            ":lib_with_deps_test",
            ":custom_module_name_test",
        ],
    )
