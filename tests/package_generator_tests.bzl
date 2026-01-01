# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Unit tests for package_generator.bzl."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//internal:package_generator.bzl", "generate_package_swift")

# =============================================================================
# Test: Basic package generation
# =============================================================================

def _basic_package_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_package_swift(
        name = "MyApp",
        dep_modules = [],
        resource_modules = [],
    )

    # Check header
    asserts.true(env, "// swift-tools-version: 5.9" in result)
    asserts.true(env, 'name: "MyApp"' in result)
    asserts.true(env, '.iOS("18.0")' in result)

    # Check main target structure
    asserts.true(env, ".target(" in result)
    asserts.true(env, 'path: "."' in result)
    # Default exclude list (users add more via extra_excludes)
    asserts.true(env, '"BUILD.bazel"' in result)
    asserts.true(env, '".deps"' in result)
    asserts.true(env, '"Package.swift"' in result)
    asserts.true(env, '"MODULE.bazel"' in result)

    return unittest.end(env)

_basic_package_test = unittest.make(_basic_package_test_impl)

# =============================================================================
# Test: Package with dependencies
# =============================================================================

def _package_with_deps_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_package_swift(
        name = "Views",
        dep_modules = ["DesignSystem", "Theme"],
        resource_modules = [],
        module_deps = {
            "Theme": ["DesignSystem"],
        },
    )

    # Check dependency targets are created
    asserts.true(env, '.target(name: "DesignSystem"' in result)
    asserts.true(env, '.target(name: "Theme"' in result)
    asserts.true(env, 'path: ".deps/DesignSystem"' in result)
    asserts.true(env, 'path: ".deps/Theme"' in result)

    # Check Theme has DesignSystem as dependency
    asserts.true(env, 'name: "Theme", dependencies: ["DesignSystem"]' in result)

    # Check main target has both deps
    asserts.true(env, 'dependencies: ["DesignSystem", "Theme"]' in result)

    return unittest.end(env)

_package_with_deps_test = unittest.make(_package_with_deps_test_impl)

# =============================================================================
# Test: Package with resource modules
# =============================================================================

def _package_with_resources_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_package_swift(
        name = "Views",
        dep_modules = ["Core"],
        resource_modules = ["Resources"],
    )

    # Check resource target has correct structure
    asserts.true(env, 'name: "Resources"' in result)
    asserts.true(env, 'path: ".deps/Resources"' in result)
    asserts.true(env, 'resources: [.process("Resources")]' in result)

    # Check main target includes resource module
    asserts.true(env, '"Resources"' in result)

    return unittest.end(env)

_package_with_resources_test = unittest.make(_package_with_resources_test_impl)

# =============================================================================
# Test: Custom platform versions
# =============================================================================

def _custom_platforms_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_package_swift(
        name = "MyLib",
        dep_modules = [],
        resource_modules = [],
        ios_version = "16",
        macos_version = "14",
        tvos_version = "",
        watchos_version = "",
        visionos_version = "1",
    )

    asserts.true(env, '.iOS("16.0")' in result)
    asserts.true(env, '.macOS("14.0")' in result)
    asserts.true(env, '.visionOS("1.0")' in result)
    asserts.false(env, ".tvOS" in result)
    asserts.false(env, ".watchOS" in result)

    return unittest.end(env)

_custom_platforms_test = unittest.make(_custom_platforms_test_impl)

# =============================================================================
# Test: Resource modules filtered from dep_modules
# =============================================================================

def _resource_filtering_test_impl(ctx):
    env = unittest.begin(ctx)

    # If a module is in both dep_modules and resource_modules,
    # it should only appear as a resource module
    result = generate_package_swift(
        name = "Views",
        dep_modules = ["Core", "Resources"],
        resource_modules = ["Resources"],
    )

    # Count occurrences of target definitions
    # Resources should appear once (as resource target), not twice
    lines = result.split("\n")
    resources_target_count = 0
    for line in lines:
        if 'name: "Resources"' in line:
            resources_target_count += 1

    asserts.equals(env, 1, resources_target_count)

    return unittest.end(env)

_resource_filtering_test = unittest.make(_resource_filtering_test_impl)

# =============================================================================
# Test: Module dependencies exclude self-references
# =============================================================================

def _no_self_deps_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_package_swift(
        name = "Views",
        dep_modules = ["DesignSystem"],
        resource_modules = [],
        module_deps = {
            "DesignSystem": ["DesignSystem"],  # Self-reference should be filtered
        },
    )

    # DesignSystem should have empty deps, not reference itself
    asserts.true(env, 'name: "DesignSystem", dependencies: []' in result)

    return unittest.end(env)

_no_self_deps_test = unittest.make(_no_self_deps_test_impl)

# =============================================================================
# Test: Module dependencies filter to available modules only
# =============================================================================

def _deps_filter_unavailable_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_package_swift(
        name = "Views",
        dep_modules = ["Core"],
        resource_modules = [],
        module_deps = {
            "Core": ["NonExistent", "AlsoNotThere"],
        },
    )

    # Core should have empty deps since referenced modules don't exist
    asserts.true(env, 'name: "Core", dependencies: []' in result)

    return unittest.end(env)

_deps_filter_unavailable_test = unittest.make(_deps_filter_unavailable_test_impl)

# =============================================================================
# Test suite
# =============================================================================

def package_generator_test_suite(name):
    """Create the test suite for package_generator.bzl.

    Args:
        name: The name of the test suite
    """
    unittest.suite(
        name,
        _basic_package_test,
        _package_with_deps_test,
        _package_with_resources_test,
        _custom_platforms_test,
        _resource_filtering_test,
        _no_self_deps_test,
        _deps_filter_unavailable_test,
    )
