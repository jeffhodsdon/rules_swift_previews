// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

public struct HelloView: View {
    public init() {}

    public var body: some View {
        Text("Hello, SwiftUI Previews!")
            .font(.title)
            .padding()
    }
}

#Preview {
    HelloView()
}
