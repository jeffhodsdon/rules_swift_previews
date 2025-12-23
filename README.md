# rules_swift_previews

Bazel rules for generating SPM Package.swift files to enable SwiftUI Previews in Xcode for Bazel-built iOS projects.

## Problem

When using Bazel to build iOS apps, SwiftUI Previews don't work because Xcode expects an SPM Package.swift structure. This ruleset bridges that gap by:

1. Collecting source files from your `swift_library` and its dependencies via a Bazel aspect
2. Generating a `Package.swift` that mirrors your dependency structure
3. Copying dependency sources to a `.deps/` directory
4. Optionally integrating with `rules_swift_resources` for resource module support

## Quick Start

### MODULE.bazel

```python
bazel_dep(name = "rules_swift_previews", version = "1.0.0")

swift_previews = use_extension(
    "@rules_swift_previews//:extensions.bzl",
    "swift_previews",
)
swift_previews.configure()
use_repo(swift_previews, "swift_preview_rules")
```

### BUILD.bazel

```python
load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("@swift_preview_rules//:defs.bzl", "SWIFT_PREVIEW_EXCLUDES", "swift_previews_package")

swift_library(
    name = "MyViews",
    srcs = glob(["*.swift"], exclude = SWIFT_PREVIEW_EXCLUDES),
    deps = [...],
)

swift_previews_package(
    name = "previews",
    lib = ":MyViews",
)
```

### Usage

```bash
# Generate Package.swift and dependency files
bazel run //path/to/views:previews

# Open in Xcode for previews
open path/to/views/
```

## With SwiftResources Integration

If you use `rules_swift_resources` for type-safe resource access:

```python
# MODULE.bazel
bazel_dep(name = "rules_swift_previews", version = "1.0.0")
bazel_dep(name = "rules_swift_resources", version = "1.0.0")

swift_previews = use_extension(
    "@rules_swift_previews//:extensions.bzl",
    "swift_previews",
)
swift_previews.configure(
    enable_swift_resources = True,
    sr_label = "@rules_swift_resources//:sr",
)
use_repo(swift_previews, "swift_preview_rules")
```

Resource modules (`swift_resources_library`) are automatically detected and included in the generated Package.swift.

## Generated Structure

```
Views/
├── Package.swift              # Generated
├── YourView.swift             # Your source files (untouched)
├── BUILD.bazel
└── .deps/                     # Generated
    ├── ModuleA/
    ├── ModuleB/
    └── ResourceModule/
        ├── Resources/
        └── ResourceModule.swift
```

## API Reference

### `swift_previews_package`

| Attribute | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | string | required | Target name (typically "previews") |
| `lib` | label | required | The `swift_library` target |
| `ios_version` | string | "18" | iOS deployment target |
| `macos_version` | string | "" | macOS deployment target (empty to omit) |
| `tvos_version` | string | "" | tvOS deployment target (empty to omit) |
| `watchos_version` | string | "" | watchOS deployment target (empty to omit) |
| `visionos_version` | string | "" | visionOS deployment target (empty to omit) |

### `SWIFT_PREVIEW_EXCLUDES`

Glob patterns to exclude from `swift_library` sources:
- `Package.swift` - Generated file
- `*+Previews.swift` - Preview-only files

## Examples

The `examples/` directory contains working examples demonstrating different use cases.

### Running an Example

Each example is a standalone Bazel workspace:

```bash
cd examples/basic

# Generate the preview package
bazel run //Views:previews

# Open in Xcode for SwiftUI Previews
open Views/Package.swift
```

In Xcode, open the Swift file and the preview canvas will render your SwiftUI views.

### Available Examples

| Example | Description |
|---------|-------------|
| `basic` | Minimal single-module example |
| `multi_level_deps` | Transitive dependencies: Views -> Theme -> DesignSystem |
| `swift_resources_deps` | `swift_resources_library` integration with bundled resources |
