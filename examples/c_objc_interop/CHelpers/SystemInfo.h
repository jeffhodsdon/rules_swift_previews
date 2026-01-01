// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#ifndef SYSTEM_INFO_H
#define SYSTEM_INFO_H

#include <stdint.h>
#include <stddef.h>

/// Get the number of CPU cores
int sysinfo_cpu_count(void);

/// Get physical memory size in bytes
uint64_t sysinfo_physical_memory(void);

/// Get the machine model identifier (e.g., "MacBookPro18,1")
/// @param buffer Output buffer
/// @param buffer_size Size of output buffer
/// @return 0 on success, -1 on failure
int sysinfo_machine_model(char *buffer, size_t buffer_size);

/// Get the OS version string (e.g., "14.0")
/// @param buffer Output buffer
/// @param buffer_size Size of output buffer
/// @return 0 on success, -1 on failure
int sysinfo_os_version(char *buffer, size_t buffer_size);

/// Get system uptime in seconds
uint64_t sysinfo_uptime_seconds(void);

#endif // SYSTEM_INFO_H
