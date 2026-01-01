// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import SwiftUI
import SystemUtilities

// MARK: - View Model

@Observable
public final class SystemDemoViewModel {
    var systemInfo: SystemUtilities.SystemInfo?
    var userInfo: SystemUtilities.UserInfo?
    var hashInput: String = "Hello, World!"
    var sha256Hash: String = ""
    var md5Hash: String = ""
    var compressionInput: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. " +
        "Sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. " +
        "Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris."
    var compressionResult: SystemUtilities.CompressionResult?
    var timingOverhead: UInt64 = 0
    var lastOperationTime: Double = 0

    public init() {
        refresh()
    }

    func refresh() {
        let start = SystemUtilities.currentTimestamp()

        systemInfo = SystemUtilities.systemInfo()
        userInfo = SystemUtilities.currentUser()
        updateHashes()
        updateCompression()
        timingOverhead = SystemUtilities.timingOverhead()

        let end = SystemUtilities.currentTimestamp()
        lastOperationTime = SystemUtilities.measureTime(from: start, to: end).milliseconds
    }

    func updateHashes() {
        sha256Hash = SystemUtilities.sha256(hashInput)
        md5Hash = SystemUtilities.md5(hashInput.data(using: .utf8) ?? Data())
    }

    func updateCompression() {
        if let data = compressionInput.data(using: .utf8) {
            compressionResult = SystemUtilities.compress(data)
        }
    }
}

// MARK: - Main View

public struct SystemDemoView: View {
    @State private var viewModel = SystemDemoViewModel()

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                header
                systemInfoSection
                userInfoSection
                cryptoSection
                compressionSection
                timingSection
            }
            .padding(24)
        }
        .frame(minWidth: 500, minHeight: 700)
        .background(Color(white: 0.97))
    }

    private var header: some View {
        VStack(spacing: 8) {
            Text("C Interop Demo")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("5 System APIs: CommonCrypto • sysctl • zlib • mach • getpwuid")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button("Refresh All") {
                viewModel.refresh()
            }
            .buttonStyle(.bordered)
        }
    }

    // MARK: - System Info Section

    private var systemInfoSection: some View {
        SectionCard(title: "System Info", subtitle: "via sysctl", icon: "cpu") {
            if let info = viewModel.systemInfo {
                InfoRow(label: "CPU Cores", value: "\(info.cpuCount)")
                InfoRow(label: "Memory", value: info.formattedMemory)
                InfoRow(label: "Model", value: info.machineModel ?? "Unknown")
                InfoRow(label: "macOS", value: info.osVersion ?? "Unknown")
                InfoRow(label: "Uptime", value: info.formattedUptime)
            }
        }
    }

    // MARK: - User Info Section

    private var userInfoSection: some View {
        SectionCard(title: "User Info", subtitle: "via getpwuid", icon: "person.circle") {
            if let info = viewModel.userInfo {
                InfoRow(label: "UID", value: "\(info.uid)")
                InfoRow(label: "Username", value: info.username ?? "Unknown")
                InfoRow(label: "Full Name", value: info.fullName ?? "Unknown")
                InfoRow(label: "Home", value: info.homeDirectory ?? "Unknown")
                InfoRow(label: "Shell", value: info.shell ?? "Unknown")
            }
        }
    }

    // MARK: - Crypto Section

    private var cryptoSection: some View {
        SectionCard(title: "Hashing", subtitle: "via CommonCrypto", icon: "lock.shield") {
            VStack(alignment: .leading, spacing: 12) {
                TextField("Input text", text: $viewModel.hashInput)
                    .textFieldStyle(.roundedBorder)
                    .onChange(of: viewModel.hashInput) { _, _ in
                        viewModel.updateHashes()
                    }

                InfoRow(label: "SHA256", value: viewModel.sha256Hash, mono: true)
                InfoRow(label: "MD5", value: viewModel.md5Hash, mono: true)
            }
        }
    }

    // MARK: - Compression Section

    private var compressionSection: some View {
        SectionCard(title: "Compression", subtitle: "via zlib", icon: "archivebox") {
            VStack(alignment: .leading, spacing: 12) {
                TextEditor(text: $viewModel.compressionInput)
                    .font(.system(.body, design: .monospaced))
                    .frame(height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                    .onChange(of: viewModel.compressionInput) { _, _ in
                        viewModel.updateCompression()
                    }

                if let result = viewModel.compressionResult {
                    InfoRow(label: "Original", value: "\(result.originalSize) bytes")
                    InfoRow(label: "Compressed", value: "\(result.compressedSize) bytes")
                    InfoRow(label: "Ratio", value: String(format: "%.1f%% saved", result.percentSaved))
                }
            }
        }
    }

    // MARK: - Timing Section

    private var timingSection: some View {
        SectionCard(title: "Timing", subtitle: "via mach_absolute_time", icon: "clock") {
            InfoRow(label: "Call Overhead", value: "\(viewModel.timingOverhead) ns/call")
            InfoRow(label: "Last Refresh", value: String(format: "%.3f ms", viewModel.lastOperationTime))
        }
    }
}

// MARK: - Helper Views

struct SectionCard<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }

            content()
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }
}

struct InfoRow: View {
    let label: String
    let value: String
    var mono: Bool = false

    var body: some View {
        HStack {
            Text(label)
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)
            Text(value)
                .font(mono ? .system(.body, design: .monospaced) : .body)
                .fontWeight(.medium)
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer()
        }
        .font(.callout)
    }
}

// MARK: - Previews

#Preview("System Demo") {
    SystemDemoView()
}

#Preview("Dark Mode") {
    SystemDemoView()
        .preferredColorScheme(.dark)
}
