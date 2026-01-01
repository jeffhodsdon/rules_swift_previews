// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#include "CryptoHelpers.h"
#include <CommonCrypto/CommonDigest.h>

void crypto_sha256(const uint8_t *data, size_t length, uint8_t *digest) {
    CC_SHA256(data, (CC_LONG)length, digest);
}

void crypto_md5(const uint8_t *data, size_t length, uint8_t *digest) {
    CC_MD5(data, (CC_LONG)length, digest);
}

void crypto_digest_to_hex(const uint8_t *digest, size_t digest_length, char *hex_output) {
    static const char hex_chars[] = "0123456789abcdef";
    for (size_t i = 0; i < digest_length; i++) {
        hex_output[i * 2] = hex_chars[(digest[i] >> 4) & 0x0F];
        hex_output[i * 2 + 1] = hex_chars[digest[i] & 0x0F];
    }
    hex_output[digest_length * 2] = '\0';
}
