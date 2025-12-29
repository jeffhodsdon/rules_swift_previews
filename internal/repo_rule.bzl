# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Repository rule that generates the swift_previews repository.

Generates a thin wrapper that optionally adds the sr binary for
Swift resource accessor generation.
"""

def _swift_previews_repository_impl(ctx):
    """Generate the swift_previews repository."""

    ctx.template("BUILD.bazel", ctx.attr._build_tpl)

    if ctx.attr.swift_resources:
        ctx.template(
            "defs.bzl",
            ctx.attr._defs_with_sr_tpl,
            substitutions = {"{sr_label}": ctx.attr.swift_resources},
        )
    else:
        ctx.template(
            "defs.bzl",
            ctx.attr._defs_basic_tpl,
        )

swift_previews_repository = repository_rule(
    implementation = _swift_previews_repository_impl,
    attrs = {
        "swift_resources": attr.string(
            default = "",
            doc = "Label for the sr binary. Enables Swift resource accessor generation.",
        ),
        "_build_tpl": attr.label(
            default = "//internal/templates:BUILD.bazel.tpl",
        ),
        "_defs_basic_tpl": attr.label(
            default = "//internal/templates:defs_basic.bzl.tpl",
        ),
        "_defs_with_sr_tpl": attr.label(
            default = "//internal/templates:defs_with_sr.bzl.tpl",
        ),
    },
    doc = "Generates the swift_previews repository.",
)
