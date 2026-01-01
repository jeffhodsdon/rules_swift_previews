// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#ifndef USER_INFO_H
#define USER_INFO_H

#include <stdint.h>
#include <stddef.h>
#include <sys/types.h>

/// Get current user ID
uid_t userinfo_uid(void);

/// Get current group ID
gid_t userinfo_gid(void);

/// Get current effective user ID
uid_t userinfo_euid(void);

/// Get username for current user
/// @param buffer Output buffer
/// @param buffer_size Size of output buffer
/// @return 0 on success, -1 on failure
int userinfo_username(char *buffer, size_t buffer_size);

/// Get home directory for current user
/// @param buffer Output buffer
/// @param buffer_size Size of output buffer
/// @return 0 on success, -1 on failure
int userinfo_home_directory(char *buffer, size_t buffer_size);

/// Get full name (gecos) for current user
/// @param buffer Output buffer
/// @param buffer_size Size of output buffer
/// @return 0 on success, -1 on failure
int userinfo_full_name(char *buffer, size_t buffer_size);

/// Get shell for current user
/// @param buffer Output buffer
/// @param buffer_size Size of output buffer
/// @return 0 on success, -1 on failure
int userinfo_shell(char *buffer, size_t buffer_size);

#endif // USER_INFO_H
