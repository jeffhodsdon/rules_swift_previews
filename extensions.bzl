# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Module extension for rules_swift_previews."""

load("//internal:repo_rule.bzl", "swift_previews_repository")

def _swift_previews_impl(module_ctx):
    """Implementation of the swift_previews module extension."""

    swift_resources = None

    # Check if any module enabled swift_resources integration
    for mod in module_ctx.modules:
        if mod.tags.use_swift_resources:
            # Use canonical label format for cross-repo visibility
            swift_resources = "@@rules_swift_resources+//:sr"
            break

    swift_previews_repository(
        name = "swift_previews",
        swift_resources = swift_resources,
    )

    return module_ctx.extension_metadata(
        root_module_direct_deps = ["swift_previews"],
        root_module_direct_dev_deps = [],
    )

use_swift_resources = tag_class(
    doc = "Enable rules_swift_resources integration for generating Swift resource accessors.",
    attrs = {},
)

swift_previews = module_extension(
    implementation = _swift_previews_impl,
    tag_classes = {
        "use_swift_resources": use_swift_resources,
    },
)
