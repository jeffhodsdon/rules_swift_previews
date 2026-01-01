// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#import "SystemBridge.h"
#import "CryptoHelpers.h"
#import "SystemInfo.h"
#import "CompressionHelpers.h"
#import "TimingHelpers.h"
#import "UserInfo.h"

@implementation SystemBridge

// MARK: - Crypto

+ (NSString *)sha256HashOfData:(NSData *)data {
    uint8_t digest[CRYPTO_SHA256_DIGEST_LENGTH];
    crypto_sha256(data.bytes, data.length, digest);

    char hex[CRYPTO_SHA256_DIGEST_LENGTH * 2 + 1];
    crypto_digest_to_hex(digest, CRYPTO_SHA256_DIGEST_LENGTH, hex);

    return [NSString stringWithUTF8String:hex];
}

+ (NSString *)md5HashOfData:(NSData *)data {
    uint8_t digest[CRYPTO_MD5_DIGEST_LENGTH];
    crypto_md5(data.bytes, data.length, digest);

    char hex[CRYPTO_MD5_DIGEST_LENGTH * 2 + 1];
    crypto_digest_to_hex(digest, CRYPTO_MD5_DIGEST_LENGTH, hex);

    return [NSString stringWithUTF8String:hex];
}

+ (NSString *)sha256HashOfString:(NSString *)string {
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    return [self sha256HashOfData:data];
}

// MARK: - System Info

+ (NSInteger)cpuCount {
    return sysinfo_cpu_count();
}

+ (uint64_t)physicalMemory {
    return sysinfo_physical_memory();
}

+ (NSString *)formattedPhysicalMemory {
    uint64_t bytes = sysinfo_physical_memory();
    double gb = (double)bytes / (1024.0 * 1024.0 * 1024.0);
    return [NSString stringWithFormat:@"%.1f GB", gb];
}

+ (NSString *)machineModel {
    char buffer[256];
    if (sysinfo_machine_model(buffer, sizeof(buffer)) == 0) {
        return [NSString stringWithUTF8String:buffer];
    }
    return nil;
}

+ (NSString *)osVersion {
    char buffer[64];
    if (sysinfo_os_version(buffer, sizeof(buffer)) == 0) {
        return [NSString stringWithUTF8String:buffer];
    }
    return nil;
}

+ (uint64_t)uptimeSeconds {
    return sysinfo_uptime_seconds();
}

+ (NSString *)formattedUptime {
    uint64_t seconds = sysinfo_uptime_seconds();
    uint64_t days = seconds / 86400;
    uint64_t hours = (seconds % 86400) / 3600;
    uint64_t minutes = (seconds % 3600) / 60;

    if (days > 0) {
        return [NSString stringWithFormat:@"%llud %lluh %llum", days, hours, minutes];
    } else if (hours > 0) {
        return [NSString stringWithFormat:@"%lluh %llum", hours, minutes];
    } else {
        return [NSString stringWithFormat:@"%llum", minutes];
    }
}

// MARK: - Compression

+ (NSData *)compressData:(NSData *)data {
    size_t bound = compress_bound(data.length);
    NSMutableData *output = [NSMutableData dataWithLength:bound];

    size_t compressed_size = compress_deflate(data.bytes, data.length,
                                               output.mutableBytes, output.length);
    if (compressed_size > 0) {
        output.length = compressed_size;
        return output;
    }
    return nil;
}

+ (NSData *)decompressData:(NSData *)data expectedSize:(NSUInteger)expectedSize {
    NSMutableData *output = [NSMutableData dataWithLength:expectedSize];

    size_t decompressed_size = compress_inflate(data.bytes, data.length,
                                                 output.mutableBytes, output.length);
    if (decompressed_size > 0) {
        output.length = decompressed_size;
        return output;
    }
    return nil;
}

+ (double)compressionRatioForData:(NSData *)data {
    NSData *compressed = [self compressData:data];
    if (compressed && data.length > 0) {
        return (double)compressed.length / (double)data.length;
    }
    return 1.0;
}

// MARK: - Timing

+ (uint64_t)currentTimestamp {
    return timing_now();
}

+ (double)millisecondsFromStart:(uint64_t)start toEnd:(uint64_t)end {
    return timing_to_milliseconds(end - start);
}

+ (uint64_t)measureTimingOverhead {
    return timing_measure_overhead(10000);
}

// MARK: - User Info

+ (uid_t)currentUID {
    return userinfo_uid();
}

+ (NSString *)currentUsername {
    char buffer[256];
    if (userinfo_username(buffer, sizeof(buffer)) == 0) {
        return [NSString stringWithUTF8String:buffer];
    }
    return nil;
}

+ (NSString *)homeDirectory {
    char buffer[1024];
    if (userinfo_home_directory(buffer, sizeof(buffer)) == 0) {
        return [NSString stringWithUTF8String:buffer];
    }
    return nil;
}

+ (NSString *)fullName {
    char buffer[256];
    if (userinfo_full_name(buffer, sizeof(buffer)) == 0) {
        return [NSString stringWithUTF8String:buffer];
    }
    return nil;
}

+ (NSString *)shell {
    char buffer[256];
    if (userinfo_shell(buffer, sizeof(buffer)) == 0) {
        return [NSString stringWithUTF8String:buffer];
    }
    return nil;
}

@end
