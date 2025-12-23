// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Resources
import SwiftUI

// MARK: - Color Configuration (loaded from bundled JSON)

struct ColorConfig: Codable {
    struct ColorValue: Codable {
        var red: Double?
        var green: Double?
        var blue: Double?
        var white: Double?

        var color: Color {
            if let white = white {
                return Color(white: white)
            }
            return Color(
                red: red ?? 0,
                green: green ?? 0,
                blue: blue ?? 0
            )
        }
    }

    let primary: ColorValue
    let accent: ColorValue
    let background: ColorValue

    static let `default` = ColorConfig(
        primary: ColorValue(red: 0.4, green: 0.2, blue: 0.8, white: nil),
        accent: ColorValue(red: 1.0, green: 0.6, blue: 0.2, white: nil),
        background: ColorValue(red: nil, green: nil, blue: nil, white: 0.95)
    )

    static func load() -> ColorConfig {
        guard let data = Resources.files.colors.data,
              let config = try? JSONDecoder().decode(ColorConfig.self, from: data) else {
            return .default
        }
        return config
    }
}

// MARK: - View

public struct ResourceView: View {
    private let colors = ColorConfig.load()

    public init() {}

    public var body: some View {
        VStack(spacing: 24) {
            Text("Resources Demo")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(colors.primary.color)

            Text("Colors loaded from bundled JSON\nvia swift_resources_library")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: 32)

            HStack(spacing: 16) {
                colorSwatch("Primary", color: colors.primary.color)
                colorSwatch("Accent", color: colors.accent.color)
                colorSwatch("Background", color: colors.background.color)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(colors.background.color)
    }

    @ViewBuilder
    private func colorSwatch(_ name: String, color: Color) -> some View {
        VStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .frame(width: 60, height: 60)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.black.opacity(0.1), lineWidth: 1)
                )

            Text(name)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Previews

#Preview {
    ResourceView()
}

#Preview("Dark Mode") {
    ResourceView()
        .preferredColorScheme(.dark)
}
