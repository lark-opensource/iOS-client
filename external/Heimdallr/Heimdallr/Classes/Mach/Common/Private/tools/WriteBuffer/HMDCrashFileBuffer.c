//
//  HMDCrashFileBuffer.c
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/10.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#include <fcntl.h>
#include <unistd.h>
#include <errno.h>
#include "HMDCrashFileBuffer.h"
#include <string.h>
#include "HMDCrashMemoryBuffer.h"
#include "HMDCrashSDKLog.h"
#include "HMDMacro.h"
#include <sys/param.h>

static void hmd_log_current_opened_files(void);

FileBuffer hmd_file_open_buffer(const char *path) {
    if(unlikely(path == NULL || path[0] == '\0')) {
        SDKLog("open file error, empty file path");
        return HMDCrashFileBufferInvalid;
    }
    
    int fd = open(path, O_RDWR|O_CREAT, 0644);
    if (fd < 0) {
        SDKLog_error("open file error, errno:%d, path:%s",errno,path);
    }
    
    if (fd < 0) {
        fd = open_dprotected_np(path, O_RDWR | O_CREAT, 0x3, 0, 0644);
        if (fd < 0) {
            SDKLog_error("open_dprotected_np file error, errno:%d, path:%s",errno,path);
            if (errno == EMFILE) {
                hmd_log_current_opened_files();
            }
        }
    }
    return fd;
}

bool hmd_file_write_block(FileBuffer fd, const void *data, ssize_t bytes) {
    if (data == NULL) {
        return false;
    }
    const uint8_t * buf = (uint8_t *)data;
    ssize_t written = 0;
    int error_count = 0;
    do {
        ssize_t write_bytes = write(fd, (uint8_t *)buf + written, bytes - written);
        if(write_bytes >= 0) {
            written += write_bytes;
            error_count = 0;
        } else {
            error_count += 1;
            if (error_count > 3) {
                return false;
            }
        }
    } while (written < bytes);
    return true;
}

bool hmd_file_close_buffer(FileBuffer fd) {
    return close(fd) == 0;
}

#pragma mark - Extension

bool hmd_file_write_string(FileBuffer fd, const char *str) {
    if (str == NULL) {
        str = "";
    }
    size_t bytes = strlen(str);
    const uint8_t * buf = (uint8_t *)str;
    return hmd_file_write_block(fd,buf,bytes);
}


bool hmd_file_write_bool(FileBuffer fd, bool val) {
    return hmd_file_write_string(fd,val?"true":"false");
}

bool hmd_file_write_int64(FileBuffer fd, int64_t val) {
    char buf[128];
    if (hmd_memory_write_int64(buf, sizeof(buf), val)) {
        return hmd_file_write_string(fd,buf);
    }
    return false;
}

bool hmd_file_write_uint64(FileBuffer fd, uint64_t val) {
    char buf[128];
    if (hmd_memory_write_uint64(buf, sizeof(buf), val)) {
        return hmd_file_write_string(fd,buf);
    }
    return false;
}

bool hmd_file_write_uint64_hex(FileBuffer fd, uint64_t val) {
    char buf[128];
    if (hmd_memory_write_uint64_hex(buf, sizeof(buf), val)) {
        return hmd_file_write_string(fd,buf);
    }
    return false;
}

bool hmd_file_write_hex(FileBuffer fd, const char *val)
{
    if (val == NULL) {
        val = "";
    }
    size_t bytes = strlen(val);
    char buffer[4];
    memset(buffer, 0, sizeof(buffer));
    const uint8_t * buf = (uint8_t *)val;
    for (int i = 0; i < bytes; i++) {
        uint8_t num = buf[i];
        buffer[1] = hmd_crash_hex_array[num & 0xf];
        buffer[0] = hmd_crash_hex_array[num >> 4];
        if (!hmd_file_write_string(fd, buffer)) {
            return false;
        }
    }
    return true;
}

bool hmd_file_write_key(FileBuffer fd, const char *s) {
    return hmd_file_write_string_value(fd,s);
}

bool hmd_file_write_hex_string_value(FileBuffer fd, const char *val) {
    if (!hmd_file_write_string(fd,"\"")) {
        return false;
    }
    if (!hmd_file_write_hex(fd, val)) {
        return false;
    }
    if (!hmd_file_write_string(fd,"\"")) {
        return false;
    }
    return true;
}

bool hmd_file_write_string_value(FileBuffer fd, const char *s) {
    if (!hmd_file_write_string(fd,"\"")) {
        return false;
    }
    if (!hmd_file_write_string(fd,s)) {
        return false;
    }
    if (!hmd_file_write_string(fd,"\"")) {
        return false;
    }
    return true;
}

bool hmd_file_begin_json_array(FileBuffer fd) {
    if (!hmd_file_write_string(fd,"[")) {
        return false;
    }
    return true;
}

bool hmd_file_end_json_array(FileBuffer fd) {
    if (!hmd_file_write_string(fd,"]")) {
        return false;
    }
    return true;
}

bool hmd_file_begin_json_object(FileBuffer fd) {
    if (!hmd_file_write_string(fd,"{")) {
        return false;
    }
    return true;
}

bool hmd_file_end_json_object(FileBuffer fd) {
    if (!hmd_file_write_string(fd,"}")) {
        return false;
    }
    return true;
}

bool hmd_file_write_key_and_bool(FileBuffer fd, const char *key, bool val) {
    if (!hmd_file_write_key(fd, key)) {
        return false;
    }
    if (!hmd_file_write_string(fd, ":")) {
        return false;
    }
    if (!hmd_file_write_bool(fd, val)) {
        return false;
    }
    return true;
}

bool hmd_file_write_key_and_hex(FileBuffer fd, const char *key, const char *val) {
    if (!hmd_file_write_key(fd, key)) {
        return false;
    }
    if (!hmd_file_write_string(fd, ":")) {
        return false;
    }
    if (!hmd_file_write_hex_string_value(fd, val)) {
        return false;
    }
    return true;
}

bool hmd_file_write_key_and_string(FileBuffer fd, const char *key, const char *val) {
    if (!hmd_file_write_key(fd, key)) {
        return false;
    }
    if (!hmd_file_write_string(fd, ":")) {
        return false;
    }
    if (!hmd_file_write_string_value(fd, val)) {
        return false;
    }
    return true;
}

bool hmd_file_write_key_and_int64(FileBuffer fd, const char *key, int64_t val) {
    if (!hmd_file_write_key(fd, key)) {
        return false;
    }
    if (!hmd_file_write_string(fd, ":")) {
        return false;
    }
    if (!hmd_file_write_int64(fd, val)) {
        return false;
    }
    return true;
}

bool hmd_file_write_key_and_uint64(FileBuffer fd, const char *key, uint64_t val) {
    if (!hmd_file_write_key(fd, key)) {
        return false;
    }
    if (!hmd_file_write_string(fd, ":")) {
        return false;
    }
    if (!hmd_file_write_uint64(fd, val)) {
        return false;
    }
    return true;
}

static void hmd_log_current_opened_files(void)
{
    int flags;
    char buf[MAXPATHLEN+1] ;
    for (int fd = 0; fd < (int) FD_SETSIZE; fd++) {
        errno = 0;
        flags = fcntl(fd, F_GETFD, 0);
        if (flags == -1 && errno) {
            if (errno != EBADF) {
                return ;
            }
            else
                continue;
        }
        int ret = fcntl(fd , F_GETPATH, buf );
        if (ret == 0) {
            SDKLog_error("open file path: %s", buf);
        }
    }
}


