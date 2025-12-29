# Swift Resources Dependencies Example

This example demonstrates `swift_previews_package` with `swift_resources_library` for type-safe bundled resources.

## Structure

```
swift_resources_deps/
├── Resources/               # Resource module (swift_resources_library)
│   ├── BUILD.bazel
│   └── Resources/           # Bundled resources
│       └── colors.json
└── Views/                   # SwiftUI views using resources
    ├── BUILD.bazel
    └── ResourceView.swift
```

## Requirements

This example uses [rules_swift_resources](https://github.com/jeffhodsdon/SwiftResources) from the Bazel Central Registry.

## Usage

1. Build the views:
   ```bash
   bazel build //Views:ResourceViews
   ```

2. Generate the preview Package.swift:
   ```bash
   bazel run //Views:previews
   ```

3. Open in Xcode and use SwiftUI Previews.

## How it Works

1. `swift_resources_library` generates type-safe accessors for bundled resources:
   ```swift
   // Access bundled JSON file
   let data = Resources.files.colors.data
   ```

2. `swift_previews.use_swift_resources()` enables resource detection

3. The aspect detects `swift_resources_library` targets by their rule kind

4. Resource files are copied to `.deps/<ModuleName>/Resources/`

5. The `sr` binary generates Swift resource accessors for the SPM package

6. The generated Package.swift includes `.process("Resources")` for resource targets
