# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Module extension for rules_swift_previews."""

load("//internal:repo_rule.bzl", "swift_preview_rules_repository")

def _swift_previews_impl(module_ctx):
    """Implementation of the swift_previews module extension."""

    enable_swift_resources = False
    sr_label = None

    for mod in module_ctx.modules:
        for tag in mod.tags.configure:
            if tag.enable_swift_resources:
                enable_swift_resources = True
                # Convert the label to a canonical string that works across repos
                if tag.sr_label:
                    sr_label = str(tag.sr_label)

    swift_preview_rules_repository(
        name = "swift_preview_rules",
        enable_swift_resources = enable_swift_resources,
        sr_label = sr_label,
    )

    return module_ctx.extension_metadata(
        root_module_direct_deps = ["swift_preview_rules"],
        root_module_direct_dev_deps = [],
    )

_configure = tag_class(
    doc = "Configure rules_swift_previews.",
    attrs = {
        "enable_swift_resources": attr.bool(
            default = False,
            doc = "Enable sr binary for generating Swift resource accessors. Requires rules_swift_resources.",
        ),
        "sr_label": attr.label(
            default = None,
            doc = "Label for the sr binary from rules_swift_resources. Required when enable_swift_resources=True.",
        ),
    },
)

swift_previews = module_extension(
    implementation = _swift_previews_impl,
    tag_classes = {
        "configure": _configure,
    },
)
