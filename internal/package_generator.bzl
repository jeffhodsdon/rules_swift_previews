# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Package.swift generation logic for rules_swift_previews."""

def generate_package_swift(
        name,
        dep_modules,
        resource_modules,
        module_deps = None,
        cc_modules = None,
        objc_modules = None,
        extra_excludes = None,
        ios_version = "18",
        macos_version = "",
        tvos_version = "",
        watchos_version = "",
        visionos_version = ""):
    """Generate the Package.swift content.

    Args:
        name: The main module name (from the swift_library target)
        dep_modules: List of Swift dependency module names
        resource_modules: List of resource module names
        module_deps: Dict mapping module names to their dependency module names
        cc_modules: List of C/C++ module names
        objc_modules: List of Objective-C module names
        extra_excludes: Additional directories/files to exclude from main target
        ios_version: iOS deployment target version
        macos_version: macOS deployment target version (empty to omit)
        tvos_version: tvOS deployment target version (empty to omit)
        watchos_version: watchOS deployment target version (empty to omit)
        visionos_version: visionOS deployment target version (empty to omit)

    Returns:
        String content of the Package.swift file
    """
    if module_deps == None:
        module_deps = {}
    if cc_modules == None:
        cc_modules = []
    if objc_modules == None:
        objc_modules = []
    if extra_excludes == None:
        extra_excludes = []

    # Filter out resource modules from dep_modules to avoid duplicates
    filtered_dep_modules = [m for m in dep_modules if m not in resource_modules]

    # Build platforms array from provided versions
    platform_entries = []
    if ios_version:
        platform_entries.append('.iOS("{}.0")'.format(ios_version))
    if macos_version:
        platform_entries.append('.macOS("{}.0")'.format(macos_version))
    if tvos_version:
        platform_entries.append('.tvOS("{}.0")'.format(tvos_version))
    if watchos_version:
        platform_entries.append('.watchOS("{}.0")'.format(watchos_version))
    if visionos_version:
        platform_entries.append('.visionOS("{}.0")'.format(visionos_version))

    platforms_str = ", ".join(platform_entries) if platform_entries else '.iOS("18.0")'

    lines = [
        "// swift-tools-version: 5.9",
        "// GENERATED - Regenerate with: bazel run :previews",
        "",
        "import PackageDescription",
        "",
        "let package = Package(",
        '    name: "{name}",'.format(name = name),
        "    platforms: [{platforms}],".format(platforms = platforms_str),
        "    products: [",
        '        .library(name: "{name}", targets: ["{name}"]),'.format(name = name),
        "    ],",
        "    dependencies: [",
        "    ],",
        "    targets: [",
    ]

    # All available modules (for filtering deps)
    all_modules = set(filtered_dep_modules + list(resource_modules) + cc_modules + objc_modules)

    # Add C/C++ module targets first (they're typically at the bottom of the dependency tree)
    for module in cc_modules:
        deps = module_deps.get(module, [])
        deps = [d for d in deps if d in all_modules and d != module]
        deps_str = ", ".join(['"{}"'.format(d) for d in deps])
        lines.extend([
            "        .target(",
            '            name: "{module}",'.format(module = module),
            "            dependencies: [{deps}],".format(deps = deps_str),
            '            path: ".deps/{module}",'.format(module = module),
            '            publicHeadersPath: "include"',
            "        ),",
        ])

    # Add Objective-C module targets (typically depend on C modules)
    for module in objc_modules:
        deps = module_deps.get(module, [])
        deps = [d for d in deps if d in all_modules and d != module]
        deps_str = ", ".join(['"{}"'.format(d) for d in deps])
        lines.extend([
            "        .target(",
            '            name: "{module}",'.format(module = module),
            "            dependencies: [{deps}],".format(deps = deps_str),
            '            path: ".deps/{module}",'.format(module = module),
            '            publicHeadersPath: "include"',
            "        ),",
        ])

    # Add Swift dependency module targets
    for module in filtered_dep_modules:
        # Get deps from module_deps, filter to only include modules we have
        deps = module_deps.get(module, [])
        deps = [d for d in deps if d in all_modules and d != module]
        deps_str = ", ".join(['"{}"'.format(d) for d in deps])
        lines.append('        .target(name: "{module}", dependencies: [{deps}], path: ".deps/{module}"),'.format(
            module = module,
            deps = deps_str,
        ))

    # Add resource module targets - also in .deps/
    for res_module in resource_modules:
        lines.extend([
            "        .target(",
            '            name: "{name}",'.format(name = res_module),
            "            dependencies: [],",
            '            path: ".deps/{name}",'.format(name = res_module),
            '            resources: [.process("Resources")]',
            "        ),",
        ])

    # Add main view target - path is "." (the Views directory itself)
    # Include all module types in dependencies
    all_deps = cc_modules + objc_modules + filtered_dep_modules + list(resource_modules)

    # Remove duplicates while preserving order
    seen = set()
    unique_deps = []
    for d in all_deps:
        if d not in seen:
            seen.add(d)
            unique_deps.append(d)

    deps_str = ", ".join(['"{}"'.format(d) for d in unique_deps])

    # Build exclude list for the main target
    # Only include excludes that are very likely to exist in any Bazel project
    excludes = [
        "BUILD.bazel",
        ".deps",
        "Package.swift",
        "MODULE.bazel",
        "MODULE.bazel.lock",
    ]

    # Add any user-specified extra excludes (for source directories, bazel symlinks, etc.)
    excludes.extend(extra_excludes)

    # Format the exclude list
    exclude_str = ", ".join(['"{}"'.format(e) for e in excludes])

    lines.extend([
        "        .target(",
        '            name: "{name}",'.format(name = name),
        "            dependencies: [{deps}],".format(deps = deps_str),
        '            path: ".",',
        "            exclude: [{excludes}]".format(excludes = exclude_str),
        "        ),",
        "    ]",
        ")",
    ])

    return "\n".join(lines)
