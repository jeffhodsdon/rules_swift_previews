# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Shell script generation utilities for rules_swift_previews.

This module provides both pure string-based functions (for testability) and
wrapper functions that work with Bazel File objects.
"""

# =============================================================================
# Pure string functions (easily unit testable)
# =============================================================================

def generate_copy_sources_script_from_paths(dep_dirs):
    """Generate script lines to copy dependency sources to .deps/.

    Pure function that takes string paths instead of File objects.

    Args:
        dep_dirs: dict mapping module_name -> list of source short_paths (strings)

    Returns:
        List of shell script lines
    """
    lines = []
    for module_name, source_paths in dep_dirs.items():
        lines.append("# Copy {module} sources".format(module = module_name))
        lines.append('mkdir -p "$DEPS_DIR/{module}"'.format(module = module_name))
        for src_path in source_paths:
            lines.append('cp "$RUNFILES_DIR/_main/{src}" "$DEPS_DIR/{module}/"'.format(
                src = src_path,
                module = module_name,
            ))
        lines.append("")
    return lines

def generate_copy_resources_script_from_paths(resource_modules):
    """Generate script lines to copy resource files and generated source to .deps/<module>/.

    Pure function that takes string paths instead of File objects.

    Args:
        resource_modules: dict mapping module_name -> {resources: [paths], generated_source: path}

    Returns:
        List of shell script lines
    """
    lines = []
    for res_name, res_info in resource_modules.items():
        lines.append("# Copy {name} resources and generated source".format(name = res_name))
        lines.append('mkdir -p "$DEPS_DIR/{name}/Resources"'.format(name = res_name))

        # Copy resource files
        for res_path in res_info.get("resources", []):
            lines.append('cp "$RUNFILES_DIR/_main/{src}" "$DEPS_DIR/{name}/Resources/"'.format(
                src = res_path,
                name = res_name,
            ))

        # Copy generated Swift source (respects force_unwrap and all other options from original build)
        generated_source = res_info.get("generated_source")
        if generated_source:
            lines.append('cp "$RUNFILES_DIR/_main/{src}" "$DEPS_DIR/{name}/"'.format(
                src = generated_source,
                name = res_name,
            ))

        lines.append("")
    return lines

def generate_copy_cc_module_script_from_paths(cc_modules):
    """Generate script lines to copy C/C++ sources and headers to .deps/.

    Pure function that takes string paths instead of File objects.
    Sources go to .deps/<module>/, headers go to .deps/<module>/include/.

    Args:
        cc_modules: dict mapping module_name -> {srcs: [paths], hdrs: [paths]}

    Returns:
        List of shell script lines
    """
    lines = []
    for module_name, file_info in cc_modules.items():
        src_paths = file_info.get("srcs", [])
        hdr_paths = file_info.get("hdrs", [])

        lines.append("# Copy {module} C/C++ module".format(module = module_name))
        lines.append('mkdir -p "$DEPS_DIR/{module}"'.format(module = module_name))

        # Copy source files to module root
        for src_path in src_paths:
            lines.append('cp "$RUNFILES_DIR/_main/{src}" "$DEPS_DIR/{module}/"'.format(
                src = src_path,
                module = module_name,
            ))

        # Copy headers to include/ subdirectory
        if hdr_paths:
            lines.append('mkdir -p "$DEPS_DIR/{module}/include"'.format(module = module_name))
            for hdr_path in hdr_paths:
                lines.append('cp "$RUNFILES_DIR/_main/{hdr}" "$DEPS_DIR/{module}/include/"'.format(
                    hdr = hdr_path,
                    module = module_name,
                ))

        lines.append("")
    return lines

def generate_copy_objc_module_script_from_paths(objc_modules):
    """Generate script lines to copy Objective-C sources and headers to .deps/.

    Pure function that takes string paths instead of File objects.
    Sources go to .deps/<module>/, headers go to .deps/<module>/include/.

    Args:
        objc_modules: dict mapping module_name -> {srcs: [paths], hdrs: [paths]}

    Returns:
        List of shell script lines
    """
    lines = []
    for module_name, file_info in objc_modules.items():
        src_paths = file_info.get("srcs", [])
        hdr_paths = file_info.get("hdrs", [])

        lines.append("# Copy {module} Objective-C module".format(module = module_name))
        lines.append('mkdir -p "$DEPS_DIR/{module}"'.format(module = module_name))

        # Copy source files to module root
        for src_path in src_paths:
            lines.append('cp "$RUNFILES_DIR/_main/{src}" "$DEPS_DIR/{module}/"'.format(
                src = src_path,
                module = module_name,
            ))

        # Copy headers to include/ subdirectory
        if hdr_paths:
            lines.append('mkdir -p "$DEPS_DIR/{module}/include"'.format(module = module_name))
            for hdr_path in hdr_paths:
                lines.append('cp "$RUNFILES_DIR/_main/{hdr}" "$DEPS_DIR/{module}/include/"'.format(
                    hdr = hdr_path,
                    module = module_name,
                ))

        lines.append("")
    return lines

# =============================================================================
# File object wrappers (used by rule implementation)
# =============================================================================

def generate_copy_sources_script(dep_dirs):
    """Generate script lines to copy dependency sources to .deps/.

    Args:
        dep_dirs: dict mapping module_name -> list of source File objects

    Returns:
        List of shell script lines
    """
    path_dict = {
        module_name: [src.short_path for src in sources]
        for module_name, sources in dep_dirs.items()
    }
    return generate_copy_sources_script_from_paths(path_dict)

def generate_copy_resources_script(resource_modules):
    """Generate script lines to copy resource files and generated source to .deps/<module>/.

    Args:
        resource_modules: dict mapping module_name -> {resources: [File], generated_source: File}

    Returns:
        List of shell script lines
    """
    path_dict = {}
    for res_name, res_info in resource_modules.items():
        path_dict[res_name] = {
            "resources": [f.short_path for f in res_info.get("resources", [])],
            "generated_source": res_info["generated_source"].short_path if res_info.get("generated_source") else None,
        }
    return generate_copy_resources_script_from_paths(path_dict)

def generate_copy_cc_module_script(cc_modules):
    """Generate script lines to copy C/C++ sources and headers to .deps/.

    Args:
        cc_modules: dict mapping module_name -> {srcs: [File], hdrs: [File]}

    Returns:
        List of shell script lines
    """
    path_dict = {}
    for module_name, file_info in cc_modules.items():
        path_dict[module_name] = {
            "srcs": [f.short_path for f in file_info.get("srcs", [])],
            "hdrs": [f.short_path for f in file_info.get("hdrs", [])],
        }
    return generate_copy_cc_module_script_from_paths(path_dict)

def generate_copy_objc_module_script(objc_modules):
    """Generate script lines to copy Objective-C sources and headers to .deps/.

    Args:
        objc_modules: dict mapping module_name -> {srcs: [File], hdrs: [File]}

    Returns:
        List of shell script lines
    """
    path_dict = {}
    for module_name, file_info in objc_modules.items():
        path_dict[module_name] = {
            "srcs": [f.short_path for f in file_info.get("srcs", [])],
            "hdrs": [f.short_path for f in file_info.get("hdrs", [])],
        }
    return generate_copy_objc_module_script_from_paths(path_dict)

def generate_base_script(package_dir):
    """Generate the base shell script setup lines.

    Args:
        package_dir: Path to the package directory

    Returns:
        List of shell script lines
    """
    return [
        "#!/bin/bash",
        "set -e",
        "",
        "# BUILD_WORKSPACE_DIRECTORY is set by Bazel during 'bazel run'",
        'if [ -z "$BUILD_WORKSPACE_DIRECTORY" ]; then',
        '  echo "Error: This script must be run via bazel run"',
        "  exit 1",
        "fi",
        "",
        "# Get runfiles directory",
        'RUNFILES_DIR="${BASH_SOURCE[0]}.runfiles"',
        'if [ ! -d "$RUNFILES_DIR" ]; then',
        '  RUNFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"',
        "fi",
        "",
        "# Package directory is the Views directory itself",
        'PACKAGE_DIR="$BUILD_WORKSPACE_DIRECTORY/{package_dir}"'.format(package_dir = package_dir),
        'DEPS_DIR="$PACKAGE_DIR/.deps"',
        "",
        'echo "Generating preview package at $PACKAGE_DIR"',
        "",
        "# Clean and create deps directory",
        'rm -rf "$DEPS_DIR"',
        'mkdir -p "$DEPS_DIR"',
        "",
    ]

def generate_package_write_script(package_swift_content):
    """Generate script lines to write Package.swift.

    Args:
        package_swift_content: The Package.swift file content

    Returns:
        List of shell script lines
    """
    return [
        "# Write Package.swift",
        'cat > "$PACKAGE_DIR/Package.swift" << \'PACKAGE_EOF\'',
        package_swift_content,
        "PACKAGE_EOF",
        "",
        'echo "Preview package generated successfully!"',
        'echo "Open with: open $PACKAGE_DIR"',
    ]
