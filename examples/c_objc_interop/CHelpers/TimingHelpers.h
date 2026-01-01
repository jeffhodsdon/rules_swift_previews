// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#ifndef TIMING_HELPERS_H
#define TIMING_HELPERS_H

#include <stdint.h>

/// Get current high-resolution timestamp (mach absolute time)
uint64_t timing_now(void);

/// Convert mach absolute time difference to nanoseconds
uint64_t timing_to_nanoseconds(uint64_t elapsed);

/// Convert mach absolute time difference to milliseconds
double timing_to_milliseconds(uint64_t elapsed);

/// Get elapsed nanoseconds between two timestamps
uint64_t timing_elapsed_ns(uint64_t start, uint64_t end);

/// Simple benchmark helper - returns nanoseconds for a given iteration count
/// (useful for measuring function call overhead)
uint64_t timing_measure_overhead(int iterations);

#endif // TIMING_HELPERS_H
