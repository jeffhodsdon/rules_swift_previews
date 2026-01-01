# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Module extension for rules_swift_previews.

Note: This extension is kept for potential future use. Load rules directly
from @rules_swift_previews//:defs.bzl instead of using an extension repo.
"""

def _swift_previews_impl(module_ctx):
    """No-op implementation - load directly from @rules_swift_previews//:defs.bzl."""
    return module_ctx.extension_metadata(
        root_module_direct_deps = [],
        root_module_direct_dev_deps = [],
    )

swift_previews = module_extension(
    implementation = _swift_previews_impl,
    tag_classes = {},
)
