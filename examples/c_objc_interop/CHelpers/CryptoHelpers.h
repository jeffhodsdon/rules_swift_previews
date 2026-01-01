// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#ifndef CRYPTO_HELPERS_H
#define CRYPTO_HELPERS_H

#include <stdint.h>
#include <stddef.h>

// SHA256 digest length (32 bytes)
#define CRYPTO_SHA256_DIGEST_LENGTH 32

// MD5 digest length (16 bytes)
#define CRYPTO_MD5_DIGEST_LENGTH 16

/// Compute SHA256 hash of data
/// @param data Input data to hash
/// @param length Length of input data
/// @param digest Output buffer (must be at least CRYPTO_SHA256_DIGEST_LENGTH bytes)
void crypto_sha256(const uint8_t *data, size_t length, uint8_t *digest);

/// Compute MD5 hash of data (for checksums, not security)
/// @param data Input data to hash
/// @param length Length of input data
/// @param digest Output buffer (must be at least CRYPTO_MD5_DIGEST_LENGTH bytes)
void crypto_md5(const uint8_t *data, size_t length, uint8_t *digest);

/// Convert digest bytes to hex string
/// @param digest Input digest bytes
/// @param digest_length Length of digest
/// @param hex_output Output buffer (must be at least digest_length * 2 + 1 bytes)
void crypto_digest_to_hex(const uint8_t *digest, size_t digest_length, char *hex_output);

#endif // CRYPTO_HELPERS_H
