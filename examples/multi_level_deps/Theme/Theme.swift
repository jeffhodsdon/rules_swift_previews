// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import DesignSystem
import SwiftUI

public enum DefaultTheme: DesignSystemVariant {
    public static func create() -> DesignSystem {
        DesignSystem(
            colors: DesignSystem.Colors(
                primary: Color(red: 0.2, green: 0.5, blue: 1.0),
                secondary: Color(red: 0.6, green: 0.6, blue: 0.7),
                background: Color(white: 0.98),
                surface: Color(white: 0.94),
                text: .primary,
                textSecondary: .secondary
            ),
            spacing: DesignSystem.Spacing(
                xs: 4,
                sm: 8,
                md: 16,
                lg: 24,
                xl: 32
            ),
            cornerRadius: DesignSystem.CornerRadius(
                sm: 6,
                md: 12,
                lg: 20
            )
        )
    }
}
