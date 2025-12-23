// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import DesignSystem
import SwiftUI
import Theme

// MARK: - ViewModel Protocol

public protocol WelcomeViewModel: Observable {
    var title: String { get }
    var subtitle: String { get }
    var buttonTitle: String { get }
    var isLoading: Bool { get }
    func onButtonTapped()
}

// MARK: - View

public struct WelcomeView<VM: WelcomeViewModel>: View {
    @State var viewModel: VM
    @Environment(\.designSystem) private var ds

    public init(viewModel: VM) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: ds.spacing.lg) {
            Text(viewModel.title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundStyle(ds.colors.text)

            Text(viewModel.subtitle)
                .font(.body)
                .foregroundStyle(ds.colors.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()
                .frame(height: ds.spacing.xl)

            Button(action: viewModel.onButtonTapped) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(viewModel.buttonTitle)
                        .fontWeight(.semibold)
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, ds.spacing.md)
            .background(ds.colors.primary)
            .clipShape(RoundedRectangle(cornerRadius: ds.cornerRadius.md))
        }
        .padding(ds.spacing.xl)
        .background(ds.colors.background)
    }
}

// MARK: - Preview Mock

@Observable
private final class MockWelcomeViewModel: WelcomeViewModel {
    var title = "Welcome"
    var subtitle = "This view demonstrates SwiftUI Previews\nworking with Bazel via rules_swift_previews."
    var buttonTitle = "Get Started"
    var isLoading = false

    func onButtonTapped() {
        isLoading = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.isLoading = false
            self?.title = "Tapped!"
        }
    }
}

// MARK: - Previews

#Preview {
    WelcomeView(viewModel: MockWelcomeViewModel())
        .designSystem(DefaultTheme.self)
}

#Preview("Dark Mode") {
    WelcomeView(viewModel: MockWelcomeViewModel())
        .designSystem(DefaultTheme.self)
        .preferredColorScheme(.dark)
}
