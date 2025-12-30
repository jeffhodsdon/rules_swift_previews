# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Package.swift generation logic for rules_swift_previews."""

def generate_package_swift(
        name,
        dep_modules,
        resource_modules,
        module_deps = None,
        ios_version = "18",
        macos_version = "",
        tvos_version = "",
        watchos_version = "",
        visionos_version = ""):
    """Generate the Package.swift content.

    Args:
        name: The main module name (from the swift_library target)
        dep_modules: List of dependency module names
        resource_modules: List of resource module names
        module_deps: Dict mapping module names to their dependency module names
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
    all_modules = set(filtered_dep_modules + list(resource_modules))

    # Add dependency module targets - paths point to .deps/
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
    all_deps = filtered_dep_modules + list(resource_modules)

    # Remove duplicates while preserving order
    seen = set()
    unique_deps = []
    for d in all_deps:
        if d not in seen:
            seen.add(d)
            unique_deps.append(d)

    deps_str = ", ".join(['"{}"'.format(d) for d in unique_deps])
    lines.extend([
        "        .target(",
        '            name: "{name}",'.format(name = name),
        "            dependencies: [{deps}],".format(deps = deps_str),
        '            path: ".",',
        '            exclude: ["BUILD.bazel", ".deps", "Package.swift", "Package.resolved"]',
        "        ),",
        "    ]",
        ")",
    ])

    return "\n".join(lines)
