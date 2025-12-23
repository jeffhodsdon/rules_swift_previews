# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Non-bzlmod entry point for rules_swift_previews.

This file provides a fallback for users not using bzlmod (WORKSPACE-based projects).
Note: This basic version does NOT support automatic resource module detection.
For resource support, migrate to bzlmod and set enable_resources = True.
"""

load("//internal:core.bzl", _swift_previews_package = "swift_previews_package")
load("//internal:providers.bzl", _SourceFilesInfo = "SourceFilesInfo")

# Re-export for users
SourceFilesInfo = _SourceFilesInfo
swift_previews_package = _swift_previews_package

# Files to exclude from production builds (preview-only files)
SWIFT_PREVIEW_EXCLUDES = [
    "Package.swift",
    "*+Previews.swift",
]
