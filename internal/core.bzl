# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Core implementation for rules_swift_previews.

Uses convention-based resource detection (checks rule kind) rather than
importing SwiftResourceInfo. This allows a single unified implementation.
"""

load("//internal:package_generator.bzl", "generate_package_swift")
load("//internal:providers.bzl", "SourceFilesInfo")
load("//internal:script_generator.bzl",
     "generate_base_script",
     "generate_copy_resources_script",
     "generate_copy_sources_script",
     "generate_package_write_script",
     "generate_sr_script")

# Rule kinds for swift_resources_library (convention-based detection)
# The macro creates a wrapper rule, so we check for both
_RESOURCE_LIBRARY_RULE_KINDS = [
    "swift_resources_library",
    "_swift_resources_library_wrapper",
]

def _source_collector_aspect_impl(target, ctx):
    """Aspect that collects source files and resources from swift_library targets.

    Resource modules are detected by convention (checking rule kind) rather
    than requiring SwiftResourceInfo provider import.
    """
    sources = []
    module_sources = {}
    resource_modules = {}
    module_deps = {}

    # Skip external dependencies
    label = target.label
    if label.workspace_name != "" or label.package.startswith("external"):
        return [SourceFilesInfo(
            sources = depset([]),
            module_sources = {},
            resource_modules = {},
            module_deps = {},
        )]

    # Convention-based resource detection: check if this is a swift_resources_library
    if ctx.rule.kind in _RESOURCE_LIBRARY_RULE_KINDS:
        module_name = target.label.name
        if hasattr(ctx.rule.attr, "module_name") and ctx.rule.attr.module_name:
            module_name = ctx.rule.attr.module_name

        # Extract resource files from files, fonts, images attributes
        resource_files = []
        for attr_name in ["files", "fonts", "images"]:
            if hasattr(ctx.rule.attr, attr_name):
                for res in getattr(ctx.rule.attr, attr_name):
                    resource_files.extend(res.files.to_list())
        if resource_files:
            resource_modules[module_name] = resource_files

    # Get the module name for source collection
    module_name = None
    if hasattr(ctx.rule.attr, "module_name") and ctx.rule.attr.module_name:
        module_name = ctx.rule.attr.module_name
    elif hasattr(target, "label"):
        module_name = target.label.name

    # Collect sources from this target
    if hasattr(ctx.rule.attr, "srcs"):
        target_sources = []
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                if f.path.endswith(".swift"):
                    sources.append(f)
                    target_sources.append(f)
        if module_name and target_sources:
            module_sources[module_name] = target_sources

    # Track this module's direct dependencies
    direct_dep_modules = []
    if hasattr(ctx.rule.attr, "deps"):
        for dep in ctx.rule.attr.deps:
            if SourceFilesInfo in dep:
                # Get the module name of this dep
                dep_module = dep.label.name
                if hasattr(dep, "label"):
                    dep_module = dep.label.name
                # Check for module_sources to find actual module name
                for name in dep[SourceFilesInfo].module_sources.keys():
                    if name not in direct_dep_modules:
                        direct_dep_modules.append(name)
                for name in dep[SourceFilesInfo].resource_modules.keys():
                    if name not in direct_dep_modules:
                        direct_dep_modules.append(name)

    if module_name:
        module_deps[module_name] = direct_dep_modules

    # Collect from dependencies (transitive)
    if hasattr(ctx.rule.attr, "deps"):
        for dep in ctx.rule.attr.deps:
            if SourceFilesInfo in dep:
                sources.extend(dep[SourceFilesInfo].sources.to_list())
                for name, srcs in dep[SourceFilesInfo].module_sources.items():
                    if name not in module_sources:
                        module_sources[name] = srcs
                for name, res in dep[SourceFilesInfo].resource_modules.items():
                    if name not in resource_modules:
                        resource_modules[name] = res
                for name, deps in dep[SourceFilesInfo].module_deps.items():
                    if name not in module_deps:
                        module_deps[name] = deps

    return [SourceFilesInfo(
        sources = depset(sources),
        module_sources = module_sources,
        resource_modules = resource_modules,
        module_deps = module_deps,
    )]

source_collector_aspect = aspect(
    implementation = _source_collector_aspect_impl,
    attr_aspects = ["deps"],
    doc = "Collects source files and resources from swift_library targets.",
)

def swift_previews_package_impl(ctx):
    """Implementation of the preview package generator rule.

    Exported for use by generated repository rules.
    """
    lib = ctx.attr.lib
    lib_module_name = lib.label.name

    dep_dirs = {}
    resource_modules = {}
    module_deps = {}
    all_sources = []
    all_resource_files = []

    if SourceFilesInfo in lib:
        info = lib[SourceFilesInfo]
        all_sources.extend(info.sources.to_list())
        for module_name, sources in info.module_sources.items():
            if module_name == lib_module_name:
                continue
            if module_name not in dep_dirs:
                dep_dirs[module_name] = []
            dep_dirs[module_name].extend(sources)
        for module_name, resources in info.resource_modules.items():
            resource_modules[module_name] = resources
            all_resource_files.extend(resources)
        # Collect module dependencies
        for module_name, deps in info.module_deps.items():
            if module_name != lib_module_name:
                module_deps[module_name] = deps

    # Build script
    script_lines = generate_base_script(ctx.attr.package_dir)
    script_lines.extend(generate_copy_sources_script(dep_dirs))

    # Handle resources if found
    if resource_modules:
        script_lines.extend(generate_copy_resources_script(resource_modules))

        # Generate Swift resource accessors if sr binary is available
        if hasattr(ctx.file, "_sr") and ctx.file._sr:
            script_lines.extend(generate_sr_script(resource_modules, ctx.file._sr.short_path))

    package_swift = generate_package_swift(
        name = lib_module_name,
        dep_modules = list(dep_dirs.keys()),
        resource_modules = list(resource_modules.keys()),
        module_deps = module_deps,
        ios_version = ctx.attr.ios_version,
        macos_version = ctx.attr.macos_version,
        tvos_version = ctx.attr.tvos_version,
        watchos_version = ctx.attr.watchos_version,
        visionos_version = ctx.attr.visionos_version,
    )

    script_lines.extend(generate_package_write_script(package_swift))

    script = ctx.actions.declare_file(ctx.label.name + ".sh")
    ctx.actions.write(
        output = script,
        content = "\n".join(script_lines),
        is_executable = True,
    )

    # Collect runfiles
    runfiles_files = all_sources + all_resource_files
    if hasattr(ctx.file, "_sr") and ctx.file._sr:
        runfiles_files.append(ctx.file._sr)
    runfiles = ctx.runfiles(files = runfiles_files)

    return [DefaultInfo(
        executable = script,
        runfiles = runfiles,
    )]

# Base attributes shared by all rule variants
_BASE_ATTRS = {
    "lib": attr.label(
        mandatory = True,
        aspects = [source_collector_aspect],
        doc = "The swift_library target to generate previews for",
    ),
    "package_dir": attr.string(
        mandatory = True,
        doc = "Path to the package directory",
    ),
    "ios_version": attr.string(default = "18"),
    "macos_version": attr.string(default = ""),
    "tvos_version": attr.string(default = ""),
    "watchos_version": attr.string(default = ""),
    "visionos_version": attr.string(default = ""),
}

# Basic rule (no sr binary)
swift_previews_package_rule = rule(
    implementation = swift_previews_package_impl,
    attrs = _BASE_ATTRS,
    executable = True,
    doc = "Generates an SPM Package.swift for Xcode SwiftUI previews.",
)

def swift_previews_package(
        name,
        lib,
        ios_version = "18",
        macos_version = "",
        tvos_version = "",
        watchos_version = "",
        visionos_version = "",
        visibility = None):
    """Generate an SPM Package.swift for Xcode SwiftUI previews.

    Args:
        name: Target name (typically "previews")
        lib: The swift_library target to generate previews for
        ios_version: iOS deployment target (default: "18")
        macos_version: macOS deployment target (empty to omit)
        tvos_version: tvOS deployment target (empty to omit)
        watchos_version: watchOS deployment target (empty to omit)
        visionos_version: visionOS deployment target (empty to omit)
        visibility: Bazel visibility
    """
    swift_previews_package_rule(
        name = name,
        lib = lib,
        package_dir = native.package_name(),
        ios_version = ios_version,
        macos_version = macos_version,
        tvos_version = tvos_version,
        watchos_version = watchos_version,
        visionos_version = visionos_version,
        visibility = visibility,
    )
