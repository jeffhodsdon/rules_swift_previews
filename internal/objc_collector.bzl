# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Objective-C source collection for rules_swift_previews.

This module handles collecting Objective-C source files and headers from objc_library targets.
"""

# Supported Objective-C source file extensions
_OBJC_SRC_EXTENSIONS = (".m", ".mm")

# Supported header file extensions (shared with C/C++)
_OBJC_HDR_EXTENSIONS = (".h", ".hh", ".hpp")

def collect_objc_sources(ctx, target):
    """Collect Objective-C source files and headers from an objc_library target.

    Args:
        ctx: The aspect context.
        target: The target being analyzed.

    Returns:
        A tuple of (module_name, {"srcs": [...], "hdrs": [...]}) if ObjC sources
        were found, or None if this is not an objc_library target.
    """
    if ctx.rule.kind != "objc_library":
        return None

    # Get module name - objc_library has module_name attribute directly
    module_name = None
    if hasattr(ctx.rule.attr, "module_name") and ctx.rule.attr.module_name:
        module_name = ctx.rule.attr.module_name
    else:
        module_name = target.label.name

    # Collect source files
    srcs = []
    if hasattr(ctx.rule.attr, "srcs"):
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                if f.path.endswith(_OBJC_SRC_EXTENSIONS):
                    srcs.append(f)

    # Collect header files
    hdrs = []
    if hasattr(ctx.rule.attr, "hdrs"):
        for hdr in ctx.rule.attr.hdrs:
            for f in hdr.files.to_list():
                if f.path.endswith(_OBJC_HDR_EXTENSIONS):
                    hdrs.append(f)

    # Only return if we have sources or headers
    if not srcs and not hdrs:
        return None

    return (module_name, {"srcs": srcs, "hdrs": hdrs})
