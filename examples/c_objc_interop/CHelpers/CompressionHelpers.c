// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#include "CompressionHelpers.h"
#include <zlib.h>

size_t compress_deflate(const uint8_t *input, size_t input_length,
                        uint8_t *output, size_t output_capacity) {
    uLongf dest_len = (uLongf)output_capacity;
    int result = compress2(output, &dest_len, input, (uLong)input_length, Z_DEFAULT_COMPRESSION);
    if (result == Z_OK) {
        return (size_t)dest_len;
    }
    return 0;
}

size_t compress_inflate(const uint8_t *input, size_t input_length,
                        uint8_t *output, size_t output_capacity) {
    uLongf dest_len = (uLongf)output_capacity;
    int result = uncompress(output, &dest_len, input, (uLong)input_length);
    if (result == Z_OK) {
        return (size_t)dest_len;
    }
    return 0;
}

size_t compress_bound(size_t input_length) {
    return (size_t)compressBound((uLong)input_length);
}
