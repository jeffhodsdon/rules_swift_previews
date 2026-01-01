# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""C/C++ source collection for rules_swift_previews.

This module handles collecting C/C++ source files and headers from cc_library targets.
"""

# Supported C/C++ source file extensions
_CC_SRC_EXTENSIONS = (".c", ".cc", ".cpp", ".cxx", ".c++")

# Supported C/C++ header file extensions
_CC_HDR_EXTENSIONS = (".h", ".hh", ".hpp", ".hxx", ".h++", ".inc")

def collect_cc_sources(ctx, target):
    """Collect C/C++ source files and headers from a cc_library target.

    Args:
        ctx: The aspect context.
        target: The target being analyzed.

    Returns:
        A tuple of (module_name, {"srcs": [...], "hdrs": [...]}) if C/C++ sources
        were found, or None if this is not a cc_library target.
    """
    if ctx.rule.kind != "cc_library":
        return None

    # Use target label name as module name.
    # Note: We cannot read module_name from swift_interop_hint because
    # SwiftInteropInfo is private in rules_swift.
    # See: https://github.com/bazelbuild/rules_swift/blob/master/swift/internal/swift_interop_info.bzl
    module_name = target.label.name

    # Collect source files
    srcs = []
    if hasattr(ctx.rule.attr, "srcs"):
        for src in ctx.rule.attr.srcs:
            for f in src.files.to_list():
                if f.path.endswith(_CC_SRC_EXTENSIONS):
                    srcs.append(f)

    # Collect header files
    hdrs = []
    if hasattr(ctx.rule.attr, "hdrs"):
        for hdr in ctx.rule.attr.hdrs:
            for f in hdr.files.to_list():
                if f.path.endswith(_CC_HDR_EXTENSIONS):
                    hdrs.append(f)

    # Only return if we have sources or headers
    if not srcs and not hdrs:
        return None

    return (module_name, {"srcs": srcs, "hdrs": hdrs})
