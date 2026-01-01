# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Shared providers for rules_swift_previews."""

SourceFilesInfo = provider(
    doc = "Provider that contains source files collected from library targets.",
    fields = {
        # Swift sources
        "sources": "depset of Swift source files",
        "module_sources": "dict mapping module names to their Swift source files",
        "resource_modules": "dict mapping resource module names to {resources: [...], generated_source: File}",
        "module_deps": "dict mapping module names to their dependency module names",
        # C/C++ modules (from cc_library)
        "cc_modules": "dict mapping module names to {srcs: [...], hdrs: [...]}",
        # Objective-C modules (from objc_library)
        "objc_modules": "dict mapping module names to {srcs: [...], hdrs: [...]}",
    },
)
