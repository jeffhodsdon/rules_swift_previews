// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#ifndef COMPRESSION_HELPERS_H
#define COMPRESSION_HELPERS_H

#include <stdint.h>
#include <stddef.h>

/// Compress data using zlib
/// @param input Input data
/// @param input_length Length of input data
/// @param output Output buffer (should be at least input_length + 128 bytes)
/// @param output_capacity Capacity of output buffer
/// @return Compressed size on success, 0 on failure
size_t compress_deflate(const uint8_t *input, size_t input_length,
                        uint8_t *output, size_t output_capacity);

/// Decompress data using zlib
/// @param input Compressed input data
/// @param input_length Length of compressed data
/// @param output Output buffer
/// @param output_capacity Capacity of output buffer
/// @return Decompressed size on success, 0 on failure
size_t compress_inflate(const uint8_t *input, size_t input_length,
                        uint8_t *output, size_t output_capacity);

/// Get the maximum compressed size for a given input size
size_t compress_bound(size_t input_length);

#endif // COMPRESSION_HELPERS_H
