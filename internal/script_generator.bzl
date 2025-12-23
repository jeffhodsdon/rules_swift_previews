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
    """Generate script lines to copy resource files to .deps/<module>/Resources/.

    Pure function that takes string paths instead of File objects.

    Args:
        resource_modules: dict mapping module_name -> list of resource short_paths (strings)

    Returns:
        List of shell script lines
    """
    lines = []
    for res_name, resource_paths in resource_modules.items():
        lines.append("# Copy {name} resources".format(name = res_name))
        lines.append('mkdir -p "$DEPS_DIR/{name}/Resources"'.format(name = res_name))
        for res_path in resource_paths:
            lines.append('cp "$RUNFILES_DIR/_main/{src}" "$DEPS_DIR/{name}/Resources/"'.format(
                src = res_path,
                name = res_name,
            ))
        lines.append("")
    return lines

def generate_sr_script_from_paths(resource_modules, sr_short_path):
    """Generate script lines to run SwiftResources sr generate for each resource module.

    Pure function that takes classified file info instead of File objects.

    Args:
        resource_modules: dict mapping module_name -> dict with keys:
            - "fonts": list of font basenames (strings)
            - "images": list of image basenames (strings)
            - "files": list of other file basenames (strings)
        sr_short_path: short_path to the sr binary

    Returns:
        List of shell script lines
    """
    lines = []

    # Handle external dep path prefix
    sr_path = sr_short_path
    if sr_path.startswith("../"):
        sr_path = sr_path[3:]  # Remove "../" prefix

    for res_name, file_info in resource_modules.items():
        font_files = file_info.get("fonts", [])
        image_files = file_info.get("images", [])
        other_files = file_info.get("files", [])

        lines.extend([
            "# Generate SwiftResources for {name}".format(name = res_name),
            "# Try multiple possible runfiles locations for sr",
            'SR=""',
            "for path in \\",
            '  "$RUNFILES_DIR/{sr}" \\'.format(sr = sr_path),
            '  "$RUNFILES_DIR/_main/../{sr}" \\'.format(sr = sr_path),
            '  "$RUNFILES_DIR/rules_swift_resources/sr"; do',
            '  if [ -x "$path" ]; then',
            '    SR="$path"',
            "    break",
            "  fi",
            "done",
            "",
            'if [ -n "$SR" ]; then',
            '  echo "Running SwiftResources: $SR"',
            '  "$SR" generate \\',
            "    --access-level public \\",
            '    --module-name "{name}" \\'.format(name = res_name),
            "    --bundle .module \\",
        ])

        # Add font files
        if font_files:
            lines.append("    --font-file \\")
            for filename in font_files:
                lines.append('    "$DEPS_DIR/{name}/Resources/{filename}" \\'.format(
                    name = res_name,
                    filename = filename,
                ))

        # Add image files
        if image_files:
            lines.append("    --image-file \\")
            for filename in image_files:
                lines.append('    "$DEPS_DIR/{name}/Resources/{filename}" \\'.format(
                    name = res_name,
                    filename = filename,
                ))

        # Add other files
        if other_files:
            lines.append("    --file-path \\")
            for filename in other_files:
                lines.append('    "$DEPS_DIR/{name}/Resources/{filename}" \\'.format(
                    name = res_name,
                    filename = filename,
                ))

        lines.extend([
            '    --output "$DEPS_DIR/{name}/{name}.swift"'.format(name = res_name),
            "else",
            '  echo "Warning: SwiftResources sr not found, skipping resource code generation"',
            '  echo "Searched in: $RUNFILES_DIR"',
            "fi",
            "",
        ])

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
    """Generate script lines to copy resource files to .deps/<module>/Resources/.

    Args:
        resource_modules: dict mapping module_name -> list of resource File objects

    Returns:
        List of shell script lines
    """
    path_dict = {
        res_name: [res_file.short_path for res_file in res_files]
        for res_name, res_files in resource_modules.items()
    }
    return generate_copy_resources_script_from_paths(path_dict)

def _classify_resource_file(f):
    """Classify a resource file by type based on extension.

    Args:
        f: A File object

    Returns:
        Tuple of (category, basename) where category is "fonts", "images", or "files"
    """
    path = f.path
    if path.endswith(".ttf") or path.endswith(".otf"):
        return ("fonts", f.basename)
    elif path.endswith((".png", ".jpg", ".jpeg", ".pdf", ".svg", ".heic")):
        return ("images", f.basename)
    else:
        return ("files", f.basename)

def generate_sr_script(resource_modules, sr_short_path):
    """Generate script lines to run SwiftResources sr generate for each resource module.

    Args:
        resource_modules: dict mapping module_name -> list of resource File objects
        sr_short_path: short_path to the sr binary

    Returns:
        List of shell script lines
    """
    classified = {}
    for res_name, res_files in resource_modules.items():
        file_info = {"fonts": [], "images": [], "files": []}
        for f in res_files:
            category, basename = _classify_resource_file(f)
            file_info[category].append(basename)
        classified[res_name] = file_info

    return generate_sr_script_from_paths(classified, sr_short_path)

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
        '  exit 1',
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
