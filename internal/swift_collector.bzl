# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Swift source collection for rules_swift_previews.

This module handles collecting Swift source files from swift_library targets.
"""

_SWIFT_RESOURCES_RULE_KIND = "swift_resources"

def collect_swift_sources(ctx, target):
    """Collect Swift source files from a target.

    Args:
        ctx: The aspect context.
        target: The target being analyzed.

    Returns:
        A tuple of (module_name, sources_list) if Swift sources were found,
        or None if this is not a Swift target or has no sources.
    """

    # Only handle targets with srcs attribute
    if not hasattr(ctx.rule.attr, "srcs"):
        return None

    # Get module name
    module_name = None
    if hasattr(ctx.rule.attr, "module_name") and ctx.rule.attr.module_name:
        module_name = ctx.rule.attr.module_name
    elif hasattr(target, "label"):
        module_name = target.label.name

    if not module_name:
        return None

    # Collect Swift sources
    swift_sources = []
    for src in ctx.rule.attr.srcs:
        for f in src.files.to_list():
            if f.path.endswith(".swift"):
                swift_sources.append(f)

    if not swift_sources:
        return None

    return (module_name, swift_sources)

def collect_swift_resources(ctx, target):
    """Collect resource files and generated source from a swift_resources target.

    Args:
        ctx: The aspect context.
        target: The target being analyzed.

    Returns:
        A tuple of (module_name, {resources: [...], generated_source: File}) if found,
        or None if this is not a swift_resources target.
    """
    if ctx.rule.kind != _SWIFT_RESOURCES_RULE_KIND:
        return None

    module_name = target.label.name
    if hasattr(ctx.rule.attr, "module_name") and ctx.rule.attr.module_name:
        module_name = ctx.rule.attr.module_name

    # Extract resource files from files, fonts, images, xcassets, strings attributes
    resource_files = []
    for attr_name in ["files", "fonts", "images", "xcassets", "strings"]:
        if hasattr(ctx.rule.attr, attr_name):
            for res in getattr(ctx.rule.attr, attr_name):
                resource_files.extend(res.files.to_list())

    # Get the generated Swift source file
    generated_source = None
    if hasattr(ctx.rule.attr, "generated_source") and ctx.rule.attr.generated_source:
        files = ctx.rule.attr.generated_source.files.to_list()
        if files:
            generated_source = files[0]

    if not resource_files and not generated_source:
        return None

    return (module_name, {"resources": resource_files, "generated_source": generated_source})
