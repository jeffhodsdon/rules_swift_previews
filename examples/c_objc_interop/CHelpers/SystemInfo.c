// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#include "SystemInfo.h"
#include <sys/sysctl.h>
#include <string.h>
#include <time.h>

int sysinfo_cpu_count(void) {
    int count;
    size_t size = sizeof(count);
    if (sysctlbyname("hw.ncpu", &count, &size, NULL, 0) == 0) {
        return count;
    }
    return -1;
}

uint64_t sysinfo_physical_memory(void) {
    uint64_t memory;
    size_t size = sizeof(memory);
    if (sysctlbyname("hw.memsize", &memory, &size, NULL, 0) == 0) {
        return memory;
    }
    return 0;
}

int sysinfo_machine_model(char *buffer, size_t buffer_size) {
    size_t size = buffer_size;
    if (sysctlbyname("hw.model", buffer, &size, NULL, 0) == 0) {
        return 0;
    }
    return -1;
}

int sysinfo_os_version(char *buffer, size_t buffer_size) {
    size_t size = buffer_size;
    if (sysctlbyname("kern.osproductversion", buffer, &size, NULL, 0) == 0) {
        return 0;
    }
    return -1;
}

uint64_t sysinfo_uptime_seconds(void) {
    struct timeval boottime;
    size_t size = sizeof(boottime);
    if (sysctlbyname("kern.boottime", &boottime, &size, NULL, 0) == 0) {
        time_t now = time(NULL);
        return (uint64_t)(now - boottime.tv_sec);
    }
    return 0;
}
