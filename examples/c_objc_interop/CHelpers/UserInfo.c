// Copyright 2025 Jeff Hodsdon
// SPDX-License-Identifier: Apache-2.0

#include "UserInfo.h"
#include <unistd.h>
#include <pwd.h>
#include <string.h>

uid_t userinfo_uid(void) {
    return getuid();
}

gid_t userinfo_gid(void) {
    return getgid();
}

uid_t userinfo_euid(void) {
    return geteuid();
}

static struct passwd* get_current_passwd(void) {
    return getpwuid(getuid());
}

int userinfo_username(char *buffer, size_t buffer_size) {
    struct passwd *pw = get_current_passwd();
    if (pw && pw->pw_name) {
        strncpy(buffer, pw->pw_name, buffer_size - 1);
        buffer[buffer_size - 1] = '\0';
        return 0;
    }
    return -1;
}

int userinfo_home_directory(char *buffer, size_t buffer_size) {
    struct passwd *pw = get_current_passwd();
    if (pw && pw->pw_dir) {
        strncpy(buffer, pw->pw_dir, buffer_size - 1);
        buffer[buffer_size - 1] = '\0';
        return 0;
    }
    return -1;
}

int userinfo_full_name(char *buffer, size_t buffer_size) {
    struct passwd *pw = get_current_passwd();
    if (pw && pw->pw_gecos) {
        // GECOS field may have comma-separated values, take first part
        const char *comma = strchr(pw->pw_gecos, ',');
        size_t len = comma ? (size_t)(comma - pw->pw_gecos) : strlen(pw->pw_gecos);
        if (len >= buffer_size) len = buffer_size - 1;
        strncpy(buffer, pw->pw_gecos, len);
        buffer[len] = '\0';
        return 0;
    }
    return -1;
}

int userinfo_shell(char *buffer, size_t buffer_size) {
    struct passwd *pw = get_current_passwd();
    if (pw && pw->pw_shell) {
        strncpy(buffer, pw->pw_shell, buffer_size - 1);
        buffer[buffer_size - 1] = '\0';
        return 0;
    }
    return -1;
}
