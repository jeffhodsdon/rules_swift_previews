# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Unit tests for script_generator.bzl."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load(
    "//internal:script_generator.bzl",
    "generate_base_script",
    "generate_copy_resources_script_from_paths",
    "generate_copy_sources_script_from_paths",
    "generate_package_write_script",
)

# =============================================================================
# Test: generate_base_script
# =============================================================================

def _base_script_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_base_script("MyApp/Views")
    script = "\n".join(result)

    # Check shebang and set -e
    asserts.true(env, "#!/bin/bash" in script)
    asserts.true(env, "set -e" in script)

    # Check workspace directory check
    asserts.true(env, "BUILD_WORKSPACE_DIRECTORY" in script)

    # Check package dir setup
    asserts.true(env, 'PACKAGE_DIR="$BUILD_WORKSPACE_DIRECTORY/MyApp/Views"' in script)
    asserts.true(env, 'DEPS_DIR="$PACKAGE_DIR/.deps"' in script)

    # Check cleanup
    asserts.true(env, 'rm -rf "$DEPS_DIR"' in script)
    asserts.true(env, 'mkdir -p "$DEPS_DIR"' in script)

    return unittest.end(env)

_base_script_test = unittest.make(_base_script_test_impl)

# =============================================================================
# Test: generate_copy_sources_script_from_paths
# =============================================================================

def _copy_sources_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_copy_sources_script_from_paths({
        "Core": ["path/to/Core.swift", "path/to/Utils.swift"],
        "Network": ["network/API.swift"],
    })
    script = "\n".join(result)

    # Check module directories are created
    asserts.true(env, 'mkdir -p "$DEPS_DIR/Core"' in script)
    asserts.true(env, 'mkdir -p "$DEPS_DIR/Network"' in script)

    # Check files are copied
    asserts.true(env, 'cp "$RUNFILES_DIR/_main/path/to/Core.swift" "$DEPS_DIR/Core/"' in script)
    asserts.true(env, 'cp "$RUNFILES_DIR/_main/path/to/Utils.swift" "$DEPS_DIR/Core/"' in script)
    asserts.true(env, 'cp "$RUNFILES_DIR/_main/network/API.swift" "$DEPS_DIR/Network/"' in script)

    return unittest.end(env)

_copy_sources_test = unittest.make(_copy_sources_test_impl)

# =============================================================================
# Test: generate_copy_sources_script_from_paths empty
# =============================================================================

def _copy_sources_empty_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_copy_sources_script_from_paths({})

    asserts.equals(env, [], result)

    return unittest.end(env)

_copy_sources_empty_test = unittest.make(_copy_sources_empty_test_impl)

# =============================================================================
# Test: generate_copy_resources_script_from_paths
# =============================================================================

def _copy_resources_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_copy_resources_script_from_paths({
        "Resources": {
            "resources": ["res/colors.json", "res/icon.png"],
            "generated_source": "Resources.swift",
        },
    })
    script = "\n".join(result)

    # Check Resources directory structure
    asserts.true(env, 'mkdir -p "$DEPS_DIR/Resources/Resources"' in script)

    # Check files are copied to Resources subdirectory
    asserts.true(env, 'cp "$RUNFILES_DIR/_main/res/colors.json" "$DEPS_DIR/Resources/Resources/"' in script)
    asserts.true(env, 'cp "$RUNFILES_DIR/_main/res/icon.png" "$DEPS_DIR/Resources/Resources/"' in script)

    # Check generated source is copied to module root
    asserts.true(env, 'cp "$RUNFILES_DIR/_main/Resources.swift" "$DEPS_DIR/Resources/"' in script)

    return unittest.end(env)

_copy_resources_test = unittest.make(_copy_resources_test_impl)

# =============================================================================
# Test: generate_copy_resources_script_from_paths without generated_source
# =============================================================================

def _copy_resources_no_source_test_impl(ctx):
    env = unittest.begin(ctx)

    # Test with generated_source = None (fallback case)
    result = generate_copy_resources_script_from_paths({
        "Resources": {
            "resources": ["fonts/Font.ttf"],
            "generated_source": None,
        },
    })
    script = "\n".join(result)

    # Check resources are still copied
    asserts.true(env, 'mkdir -p "$DEPS_DIR/Resources/Resources"' in script)
    asserts.true(env, 'cp "$RUNFILES_DIR/_main/fonts/Font.ttf" "$DEPS_DIR/Resources/Resources/"' in script)

    # No generated source copy should be present
    asserts.false(env, "Resources.swift" in script)

    return unittest.end(env)

_copy_resources_no_source_test = unittest.make(_copy_resources_no_source_test_impl)

# =============================================================================
# Test: generate_package_write_script
# =============================================================================

def _package_write_script_test_impl(ctx):
    env = unittest.begin(ctx)

    package_content = """// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Test")"""

    result = generate_package_write_script(package_content)
    script = "\n".join(result)

    # Check heredoc structure
    asserts.true(env, 'cat > "$PACKAGE_DIR/Package.swift"' in script)
    asserts.true(env, "PACKAGE_EOF" in script)

    # Check content is included
    asserts.true(env, package_content in script)

    # Check success message
    asserts.true(env, "Preview package generated successfully" in script)

    return unittest.end(env)

_package_write_script_test = unittest.make(_package_write_script_test_impl)

# =============================================================================
# Test suite
# =============================================================================

def script_generator_test_suite(name):
    """Create the test suite for script_generator.bzl.

    Args:
        name: The name of the test suite
    """
    unittest.suite(
        name,
        _base_script_test,
        _copy_sources_test,
        _copy_sources_empty_test,
        _copy_resources_test,
        _copy_resources_no_source_test,
        _package_write_script_test,
    )
