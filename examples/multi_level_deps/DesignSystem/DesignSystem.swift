// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import SwiftUI

// MARK: - Design Tokens

@Observable
public class DesignSystem {
    public struct Colors {
        public let primary: Color
        public let secondary: Color
        public let background: Color
        public let surface: Color
        public let text: Color
        public let textSecondary: Color

        public init(
            primary: Color,
            secondary: Color,
            background: Color,
            surface: Color,
            text: Color,
            textSecondary: Color
        ) {
            self.primary = primary
            self.secondary = secondary
            self.background = background
            self.surface = surface
            self.text = text
            self.textSecondary = textSecondary
        }
    }

    public struct Spacing {
        public let xs: CGFloat
        public let sm: CGFloat
        public let md: CGFloat
        public let lg: CGFloat
        public let xl: CGFloat

        public init(xs: CGFloat, sm: CGFloat, md: CGFloat, lg: CGFloat, xl: CGFloat) {
            self.xs = xs
            self.sm = sm
            self.md = md
            self.lg = lg
            self.xl = xl
        }
    }

    public struct CornerRadius {
        public let sm: CGFloat
        public let md: CGFloat
        public let lg: CGFloat

        public init(sm: CGFloat, md: CGFloat, lg: CGFloat) {
            self.sm = sm
            self.md = md
            self.lg = lg
        }
    }

    public let colors: Colors
    public let spacing: Spacing
    public let cornerRadius: CornerRadius

    public init(colors: Colors, spacing: Spacing, cornerRadius: CornerRadius) {
        self.colors = colors
        self.spacing = spacing
        self.cornerRadius = cornerRadius
    }
}

// MARK: - Variant Protocol

public protocol DesignSystemVariant {
    static func create() -> DesignSystem
}

// MARK: - Default Values

extension DesignSystem {
    public static let `default` = DesignSystem(
        colors: Colors(
            primary: .blue,
            secondary: .gray,
            background: Color(white: 0.98),
            surface: Color(white: 0.95),
            text: .primary,
            textSecondary: .secondary
        ),
        spacing: Spacing(xs: 4, sm: 8, md: 16, lg: 24, xl: 32),
        cornerRadius: CornerRadius(sm: 4, md: 8, lg: 16)
    )
}

// MARK: - Environment

private struct DesignSystemKey: EnvironmentKey {
    static let defaultValue = DesignSystem.default
}

public extension EnvironmentValues {
    var designSystem: DesignSystem {
        get { self[DesignSystemKey.self] }
        set { self[DesignSystemKey.self] = newValue }
    }
}

public extension View {
    func designSystem(_ ds: DesignSystem) -> some View {
        environment(\.designSystem, ds)
    }

    func designSystem(_ variant: (some DesignSystemVariant).Type) -> some View {
        environment(\.designSystem, variant.create())
    }
}
