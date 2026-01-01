// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

import Foundation
import SystemBridge

/// Swift-friendly wrapper around system utilities from C libraries.
/// Demonstrates calling C code via an Objective-C bridge.
public enum SystemUtilities {

    // MARK: - Crypto (CommonCrypto via C)

    /// Compute SHA256 hash of data
    public static func sha256(_ data: Data) -> String {
        SystemBridge.sha256Hash(of: data)
    }

    /// Compute SHA256 hash of string
    public static func sha256(_ string: String) -> String {
        SystemBridge.sha256Hash(of: string)
    }

    /// Compute MD5 hash of data (for checksums, not security)
    public static func md5(_ data: Data) -> String {
        SystemBridge.md5Hash(of: data)
    }

    // MARK: - System Info (sysctl via C)

    /// System information gathered from sysctl
    public struct SystemInfo: Sendable {
        public let cpuCount: Int
        public let physicalMemory: UInt64
        public let formattedMemory: String
        public let machineModel: String?
        public let osVersion: String?
        public let uptimeSeconds: UInt64
        public let formattedUptime: String
    }

    /// Get current system information
    public static func systemInfo() -> SystemInfo {
        SystemInfo(
            cpuCount: Int(SystemBridge.cpuCount()),
            physicalMemory: SystemBridge.physicalMemory(),
            formattedMemory: SystemBridge.formattedPhysicalMemory(),
            machineModel: SystemBridge.machineModel(),
            osVersion: SystemBridge.osVersion(),
            uptimeSeconds: SystemBridge.uptimeSeconds(),
            formattedUptime: SystemBridge.formattedUptime()
        )
    }

    // MARK: - Compression (zlib via C)

    /// Compression result with original and compressed sizes
    public struct CompressionResult: Sendable {
        public let compressedData: Data
        public let originalSize: Int
        public let compressedSize: Int
        public var ratio: Double {
            guard originalSize > 0 else { return 1.0 }
            return Double(compressedSize) / Double(originalSize)
        }
        public var percentSaved: Double {
            (1.0 - ratio) * 100.0
        }
    }

    /// Compress data using zlib
    public static func compress(_ data: Data) -> CompressionResult? {
        guard let compressed = SystemBridge.compressData(data) else { return nil }
        return CompressionResult(
            compressedData: compressed,
            originalSize: data.count,
            compressedSize: compressed.count
        )
    }

    /// Decompress data using zlib
    public static func decompress(_ data: Data, expectedSize: Int) -> Data? {
        SystemBridge.decompressData(data, expectedSize: UInt(expectedSize))
    }

    // MARK: - Timing (mach_absolute_time via C)

    /// Timing measurement result
    public struct TimingResult: Sendable {
        public let startTimestamp: UInt64
        public let endTimestamp: UInt64
        public let milliseconds: Double

        public var microseconds: Double { milliseconds * 1000 }
        public var nanoseconds: Double { milliseconds * 1_000_000 }
    }

    /// Get current high-resolution timestamp
    public static func currentTimestamp() -> UInt64 {
        SystemBridge.currentTimestamp()
    }

    /// Measure time between two timestamps
    public static func measureTime(from start: UInt64, to end: UInt64) -> TimingResult {
        TimingResult(
            startTimestamp: start,
            endTimestamp: end,
            milliseconds: SystemBridge.milliseconds(fromStart: start, toEnd: end)
        )
    }

    /// Measure the overhead of timing calls (nanoseconds per call)
    public static func timingOverhead() -> UInt64 {
        SystemBridge.measureTimingOverhead()
    }

    // MARK: - User Info (getpwuid via C)

    /// Current user information
    public struct UserInfo: Sendable {
        public let uid: UInt32
        public let username: String?
        public let fullName: String?
        public let homeDirectory: String?
        public let shell: String?
    }

    /// Get current user information
    public static func currentUser() -> UserInfo {
        UserInfo(
            uid: SystemBridge.currentUID(),
            username: SystemBridge.currentUsername(),
            fullName: SystemBridge.fullName(),
            homeDirectory: SystemBridge.homeDirectory(),
            shell: SystemBridge.shell()
        )
    }
}
