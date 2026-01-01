// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#include "TimingHelpers.h"
#include <mach/mach_time.h>

static mach_timebase_info_data_t timebase_info = {0, 0};

static void ensure_timebase_info(void) {
    if (timebase_info.denom == 0) {
        mach_timebase_info(&timebase_info);
    }
}

uint64_t timing_now(void) {
    return mach_absolute_time();
}

uint64_t timing_to_nanoseconds(uint64_t elapsed) {
    ensure_timebase_info();
    return elapsed * timebase_info.numer / timebase_info.denom;
}

double timing_to_milliseconds(uint64_t elapsed) {
    return (double)timing_to_nanoseconds(elapsed) / 1000000.0;
}

uint64_t timing_elapsed_ns(uint64_t start, uint64_t end) {
    return timing_to_nanoseconds(end - start);
}

uint64_t timing_measure_overhead(int iterations) {
    uint64_t start = timing_now();
    for (int i = 0; i < iterations; i++) {
        // Empty loop to measure call overhead
        (void)timing_now();
    }
    uint64_t end = timing_now();
    return timing_to_nanoseconds(end - start) / (uint64_t)iterations;
}
