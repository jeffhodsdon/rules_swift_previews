# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Shared providers for rules_swift_previews."""

SourceFilesInfo = provider(
    doc = "Provider that contains source files collected from swift_library targets.",
    fields = {
        "sources": "depset of source files",
        "module_sources": "dict mapping module names to their source files",
        "resource_modules": "dict mapping resource module names to their resource files",
        "module_deps": "dict mapping module names to their dependency module names",
    },
)
