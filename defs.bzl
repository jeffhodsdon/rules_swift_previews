# Copyright 2025 Jeff Hodsdon
# SPDX-License-Identifier: Apache-2.0

"""Public API for rules_swift_previews.

Swift resource modules (swift_resources_library) are automatically detected
via the aspect and their generated source files are included in the preview package.
"""

load("//internal:core.bzl", _swift_previews_package = "swift_previews_package")
load("//internal:providers.bzl", _SourceFilesInfo = "SourceFilesInfo")

SourceFilesInfo = _SourceFilesInfo
swift_previews_package = _swift_previews_package

# Files to exclude from production builds (preview-only files)
SWIFT_PREVIEW_EXCLUDES = [
    "Package.swift",
    "*+Previews.swift",
]
