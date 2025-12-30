# rules_swift_previews

Bazel rules for generating SPM Package.swift files to enable SwiftUI Previews in Xcode for Bazel-built iOS projects.

## Quick Start

### MODULE.bazel

```python
bazel_dep(name = "rules_swift_previews", version = "0.0.0")
```

### BUILD.bazel

```python
load("@rules_swift//swift:swift.bzl", "swift_library")
load("@swift_previews//:defs.bzl", "SWIFT_PREVIEW_EXCLUDES", "swift_previews_package")

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
bazel_dep(name = "rules_swift_previews", version = "0.0.0")
bazel_dep(name = "rules_swift_resources", version = "0.2.0")

swift_previews = use_extension(
    "@rules_swift_previews//:extensions.bzl",
    "swift_previews",
)
swift_previews.use_swift_resources()
use_repo(swift_previews, "swift_previews")
```

Resource modules (`swift_resources_library`) are automatically detected by rule kind and included in the generated Package.swift.

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
