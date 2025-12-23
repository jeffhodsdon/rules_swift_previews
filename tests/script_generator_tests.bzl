# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Unit tests for script_generator.bzl."""

load("@bazel_skylib//lib:unittest.bzl", "asserts", "unittest")
load("//internal:script_generator.bzl",
     "generate_base_script",
     "generate_copy_resources_script_from_paths",
     "generate_copy_sources_script_from_paths",
     "generate_package_write_script",
     "generate_sr_script_from_paths")

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
        "Resources": ["res/colors.json", "res/icon.png"],
    })
    script = "\n".join(result)

    # Check Resources directory structure
    asserts.true(env, 'mkdir -p "$DEPS_DIR/Resources/Resources"' in script)

    # Check files are copied to Resources subdirectory
    asserts.true(env, 'cp "$RUNFILES_DIR/_main/res/colors.json" "$DEPS_DIR/Resources/Resources/"' in script)
    asserts.true(env, 'cp "$RUNFILES_DIR/_main/res/icon.png" "$DEPS_DIR/Resources/Resources/"' in script)

    return unittest.end(env)

_copy_resources_test = unittest.make(_copy_resources_test_impl)

# =============================================================================
# Test: generate_sr_script_from_paths
# =============================================================================

def _sr_script_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_sr_script_from_paths(
        {
            "Resources": {
                "fonts": ["MyFont.ttf"],
                "images": ["icon.png", "logo.pdf"],
                "files": ["colors.json"],
            },
        },
        "external/rules_swift_resources/sr",
    )
    script = "\n".join(result)

    # Check sr binary lookup
    asserts.true(env, 'SR=""' in script)
    asserts.true(env, 'if [ -x "$path" ]' in script)

    # Check sr generate command
    asserts.true(env, '"$SR" generate' in script)
    asserts.true(env, '--access-level public' in script)
    asserts.true(env, '--module-name "Resources"' in script)
    asserts.true(env, '--bundle .module' in script)

    # Check font files
    asserts.true(env, '--font-file' in script)
    asserts.true(env, '$DEPS_DIR/Resources/Resources/MyFont.ttf' in script)

    # Check image files
    asserts.true(env, '--image-file' in script)
    asserts.true(env, '$DEPS_DIR/Resources/Resources/icon.png' in script)
    asserts.true(env, '$DEPS_DIR/Resources/Resources/logo.pdf' in script)

    # Check other files
    asserts.true(env, '--file-path' in script)
    asserts.true(env, '$DEPS_DIR/Resources/Resources/colors.json' in script)

    # Check output
    asserts.true(env, '--output "$DEPS_DIR/Resources/Resources.swift"' in script)

    return unittest.end(env)

_sr_script_test = unittest.make(_sr_script_test_impl)

# =============================================================================
# Test: generate_sr_script_from_paths with external prefix stripping
# =============================================================================

def _sr_script_external_prefix_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_sr_script_from_paths(
        {"Res": {"fonts": [], "images": [], "files": ["data.json"]}},
        "../rules_swift_resources/sr",
    )
    script = "\n".join(result)

    # ../rules_swift_resources/sr should become rules_swift_resources/sr
    asserts.true(env, '$RUNFILES_DIR/rules_swift_resources/sr' in script)
    asserts.false(env, '$RUNFILES_DIR/../' in script)

    return unittest.end(env)

_sr_script_external_prefix_test = unittest.make(_sr_script_external_prefix_test_impl)

# =============================================================================
# Test: generate_sr_script_from_paths fallback warning
# =============================================================================

def _sr_script_fallback_test_impl(ctx):
    env = unittest.begin(ctx)

    result = generate_sr_script_from_paths(
        {"MyRes": {"fonts": [], "images": [], "files": []}},
        "some/path/sr",
    )
    script = "\n".join(result)

    # Check fallback warning is present
    asserts.true(env, 'Warning: SwiftResources sr not found' in script)
    asserts.true(env, 'Searched in: $RUNFILES_DIR' in script)

    return unittest.end(env)

_sr_script_fallback_test = unittest.make(_sr_script_fallback_test_impl)

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
        _sr_script_test,
        _sr_script_external_prefix_test,
        _sr_script_fallback_test,
        _package_write_script_test,
    )
