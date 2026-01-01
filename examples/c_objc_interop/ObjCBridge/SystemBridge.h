// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Objective-C bridge providing Swift-friendly wrappers around C system utilities.
/// Demonstrates ObjC as a bridge layer between C and Swift.
@interface SystemBridge : NSObject

// MARK: - Crypto (CommonCrypto)

/// Compute SHA256 hash of data
+ (NSString *)sha256HashOfData:(NSData *)data;

/// Compute MD5 hash of data (for checksums, not security)
+ (NSString *)md5HashOfData:(NSData *)data;

/// Compute SHA256 hash of string
+ (NSString *)sha256HashOfString:(NSString *)string;

// MARK: - System Info (sysctl)

/// Get number of CPU cores
+ (NSInteger)cpuCount;

/// Get physical memory in bytes
+ (uint64_t)physicalMemory;

/// Get physical memory as formatted string (e.g., "16 GB")
+ (NSString *)formattedPhysicalMemory;

/// Get machine model identifier
+ (nullable NSString *)machineModel;

/// Get OS version string
+ (nullable NSString *)osVersion;

/// Get system uptime in seconds
+ (uint64_t)uptimeSeconds;

/// Get formatted uptime string (e.g., "2d 5h 30m")
+ (NSString *)formattedUptime;

// MARK: - Compression (zlib)

/// Compress data using zlib
+ (nullable NSData *)compressData:(NSData *)data;

/// Decompress data using zlib
+ (nullable NSData *)decompressData:(NSData *)data expectedSize:(NSUInteger)expectedSize;

/// Get compression ratio for data (returns 0.0-1.0, lower is better compression)
+ (double)compressionRatioForData:(NSData *)data;

// MARK: - Timing (mach_absolute_time)

/// Get current high-resolution timestamp
+ (uint64_t)currentTimestamp;

/// Convert timestamp difference to milliseconds
+ (double)millisecondsFromStart:(uint64_t)start toEnd:(uint64_t)end;

/// Measure the overhead of timing calls (returns nanoseconds per call)
+ (uint64_t)measureTimingOverhead;

// MARK: - User Info (getpwuid)

/// Get current user ID
+ (uid_t)currentUID;

/// Get current username
+ (nullable NSString *)currentUsername;

/// Get current user's home directory
+ (nullable NSString *)homeDirectory;

/// Get current user's full name
+ (nullable NSString *)fullName;

/// Get current user's shell
+ (nullable NSString *)shell;

@end

NS_ASSUME_NONNULL_END
