# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Core implementation for rules_swift_previews.

Uses convention-based resource detection (checks rule kind) rather than
importing SwiftResourceInfo. Delegates source collection to language-specific
modules for Swift, C/C++, and Objective-C.
"""

load("//internal:cc_collector.bzl", "collect_cc_sources")
load("//internal:objc_collector.bzl", "collect_objc_sources")
load("//internal:package_generator.bzl", "generate_package_swift")
load("//internal:providers.bzl", "SourceFilesInfo")
load(
    "//internal:script_generator.bzl",
    "generate_base_script",
    "generate_copy_cc_module_script",
    "generate_copy_objc_module_script",
    "generate_copy_resources_script",
    "generate_copy_sources_script",
    "generate_package_write_script",
)
load("//internal:swift_collector.bzl", "collect_swift_resources", "collect_swift_sources")

def _source_collector_aspect_impl(target, ctx):
    """Aspect that collects source files from library targets.

    Handles swift_library, cc_library, and objc_library targets.
    Resource modules are detected by convention (checking rule kind).
    """
    sources = []
    module_sources = {}
    resource_modules = {}
    module_deps = {}
    cc_modules = {}
    objc_modules = {}

    # Skip external dependencies
    label = target.label
    if label.workspace_name != "" or label.package.startswith("external"):
        return [SourceFilesInfo(
            sources = depset([]),
            module_sources = {},
            resource_modules = {},
            module_deps = {},
            cc_modules = {},
            objc_modules = {},
        )]

    # Collect from this target using language-specific collectors
    swift_result = collect_swift_sources(ctx, target)
    if swift_result:
        module_name, swift_sources = swift_result
        sources.extend(swift_sources)
        module_sources[module_name] = swift_sources

    resource_result = collect_swift_resources(ctx, target)
    if resource_result:
        module_name, resource_info = resource_result
        resource_modules[module_name] = resource_info

    cc_result = collect_cc_sources(ctx, target)
    if cc_result:
        module_name, cc_info = cc_result
        cc_modules[module_name] = cc_info

    objc_result = collect_objc_sources(ctx, target)
    if objc_result:
        module_name, objc_info = objc_result
        objc_modules[module_name] = objc_info

    # Get module name for dependency tracking
    module_name = None
    if hasattr(ctx.rule.attr, "module_name") and ctx.rule.attr.module_name:
        module_name = ctx.rule.attr.module_name
    elif hasattr(target, "label"):
        module_name = target.label.name

    # Track this module's direct dependencies
    direct_dep_modules = []
    if hasattr(ctx.rule.attr, "deps"):
        for dep in ctx.rule.attr.deps:
            if SourceFilesInfo in dep:
                dep_info = dep[SourceFilesInfo]

                # Collect module names from all dependency types
                for name in dep_info.module_sources.keys():
                    if name not in direct_dep_modules:
                        direct_dep_modules.append(name)
                for name in dep_info.resource_modules.keys():
                    if name not in direct_dep_modules:
                        direct_dep_modules.append(name)
                for name in dep_info.cc_modules.keys():
                    if name not in direct_dep_modules:
                        direct_dep_modules.append(name)
                for name in dep_info.objc_modules.keys():
                    if name not in direct_dep_modules:
                        direct_dep_modules.append(name)

    if module_name:
        module_deps[module_name] = direct_dep_modules

    # Collect from dependencies (transitive)
    if hasattr(ctx.rule.attr, "deps"):
        for dep in ctx.rule.attr.deps:
            if SourceFilesInfo in dep:
                dep_info = dep[SourceFilesInfo]
                sources.extend(dep_info.sources.to_list())
                for name, srcs in dep_info.module_sources.items():
                    if name not in module_sources:
                        module_sources[name] = srcs
                for name, res in dep_info.resource_modules.items():
                    if name not in resource_modules:
                        resource_modules[name] = res
                for name, deps in dep_info.module_deps.items():
                    if name not in module_deps:
                        module_deps[name] = deps
                for name, cc_info in dep_info.cc_modules.items():
                    if name not in cc_modules:
                        cc_modules[name] = cc_info
                for name, objc_info in dep_info.objc_modules.items():
                    if name not in objc_modules:
                        objc_modules[name] = objc_info

    return [SourceFilesInfo(
        sources = depset(sources),
        module_sources = module_sources,
        resource_modules = resource_modules,
        module_deps = module_deps,
        cc_modules = cc_modules,
        objc_modules = objc_modules,
    )]

source_collector_aspect = aspect(
    implementation = _source_collector_aspect_impl,
    attr_aspects = ["deps"],
    doc = "Collects source files from swift_library, cc_library, and objc_library targets.",
)

def swift_previews_package_impl(ctx):
    """Implementation of the preview package generator rule.

    Exported for use by generated repository rules.

    Args:
        ctx: The rule context.

    Returns:
        A list containing DefaultInfo with the executable script and runfiles.
    """
    lib = ctx.attr.lib
    lib_module_name = lib.label.name

    dep_dirs = {}
    resource_modules = {}
    module_deps = {}
    cc_modules = {}
    objc_modules = {}
    all_sources = []
    all_resource_files = []
    all_cc_files = []
    all_objc_files = []

    if SourceFilesInfo in lib:
        info = lib[SourceFilesInfo]
        all_sources.extend(info.sources.to_list())

        # Collect Swift module sources
        for module_name, sources in info.module_sources.items():
            if module_name == lib_module_name:
                continue
            if module_name not in dep_dirs:
                dep_dirs[module_name] = []
            dep_dirs[module_name].extend(sources)

        # Collect resource modules
        for module_name, res_info in info.resource_modules.items():
            resource_modules[module_name] = res_info
            all_resource_files.extend(res_info.get("resources", []))
            if res_info.get("generated_source"):
                all_resource_files.append(res_info["generated_source"])

        # Collect module dependencies
        for module_name, deps in info.module_deps.items():
            if module_name != lib_module_name:
                module_deps[module_name] = deps

        # Collect C/C++ modules
        for module_name, cc_info in info.cc_modules.items():
            cc_modules[module_name] = cc_info
            all_cc_files.extend(cc_info.get("srcs", []))
            all_cc_files.extend(cc_info.get("hdrs", []))

        # Collect Objective-C modules
        for module_name, objc_info in info.objc_modules.items():
            objc_modules[module_name] = objc_info
            all_objc_files.extend(objc_info.get("srcs", []))
            all_objc_files.extend(objc_info.get("hdrs", []))

    # Build script
    script_lines = generate_base_script(ctx.attr.package_dir)

    # Copy Swift sources
    script_lines.extend(generate_copy_sources_script(dep_dirs))

    # Copy C/C++ modules (sources + headers)
    if cc_modules:
        script_lines.extend(generate_copy_cc_module_script(cc_modules))

    # Copy Objective-C modules (sources + headers)
    if objc_modules:
        script_lines.extend(generate_copy_objc_module_script(objc_modules))

    # Handle resources if found
    if resource_modules:
        script_lines.extend(generate_copy_resources_script(resource_modules))

    package_swift = generate_package_swift(
        name = lib_module_name,
        dep_modules = list(dep_dirs.keys()),
        resource_modules = list(resource_modules.keys()),
        module_deps = module_deps,
        cc_modules = list(cc_modules.keys()),
        objc_modules = list(objc_modules.keys()),
        extra_excludes = ctx.attr.extra_excludes,
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
    runfiles_files = all_sources + all_resource_files + all_cc_files + all_objc_files
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
    "extra_excludes": attr.string_list(
        default = [],
        doc = "Additional directories/files to exclude from the main SPM target",
    ),
    "ios_version": attr.string(default = "18"),
    "macos_version": attr.string(default = ""),
    "tvos_version": attr.string(default = ""),
    "watchos_version": attr.string(default = ""),
    "visionos_version": attr.string(default = ""),
}

def create_swift_previews_rule(extra_attrs = {}):
    """Factory to create swift_previews_package rule variants.

    Args:
        extra_attrs: Additional attributes to add to the rule (e.g., _sr for SwiftResources)

    Returns:
        A rule that generates SPM Package.swift for Xcode SwiftUI previews.
    """
    attrs = dict(_BASE_ATTRS)
    attrs.update(extra_attrs)
    return rule(
        implementation = swift_previews_package_impl,
        attrs = attrs,
        executable = True,
        doc = "Generates an SPM Package.swift for Xcode SwiftUI previews.",
    )

def create_swift_previews_macro(rule_fn):
    """Factory to create swift_previews_package macro wrapper.

    Args:
        rule_fn: The rule function to wrap

    Returns:
        A macro that wraps the rule with native.package_name() for package_dir.
    """

    def swift_previews_package(
            name,
            lib,
            extra_excludes = [],
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
            extra_excludes: Additional directories/files to exclude from the main SPM target
            ios_version: iOS deployment target (default: "18")
            macos_version: macOS deployment target (empty to omit)
            tvos_version: tvOS deployment target (empty to omit)
            watchos_version: watchOS deployment target (empty to omit)
            visionos_version: visionOS deployment target (empty to omit)
            visibility: Bazel visibility
        """
        rule_fn(
            name = name,
            lib = lib,
            package_dir = native.package_name(),
            extra_excludes = extra_excludes,
            ios_version = ios_version,
            macos_version = macos_version,
            tvos_version = tvos_version,
            watchos_version = watchos_version,
            visionos_version = visionos_version,
            visibility = visibility,
        )

    return swift_previews_package

swift_previews_package_rule = create_swift_previews_rule()
swift_previews_package = create_swift_previews_macro(swift_previews_package_rule)
