//
//  HMDCrashMemoryBuffer.c
//  Heimdallr
//
//  Created by yuanzhangjing on 2019/9/20.
//

#include "HMDCrashMemoryBuffer.h"
#include <string.h>

const char hmd_crash_hex_array[] = "0123456789abcdef";

bool hmd_memory_write_int64(char *buffer, int length, int64_t val) {
    char buf[128];
    memset(buf,0,sizeof(buf));
    char *c = &buf[126];
    bool is_negtive = false;
    if (val<0) {
        val = -val;
        is_negtive = true;
    }
    do {
        *c = hmd_crash_hex_array[val % 10];
        c--;
    } while ((val /= 10) != 0);
    if (is_negtive) {
        *c = '-';
        c--;
    }
    c++;
    if (strlen(c)+1 <= length) {
        memcpy(buffer, c, strlen(c)+1);
        return true;
    }
    return false;
}

bool hmd_memory_write_uint64(char *buffer, int length, uint64_t val) {
    char buf[128];
    memset(buf,0,sizeof(buf));
    char *c = &buf[126];
    do {
        *c = hmd_crash_hex_array[val % 10];
        c--;
    } while ((val /= 10) != 0);
    c++;
    if (strlen(c)+1 <= length) {
        memcpy(buffer, c, strlen(c)+1);
        return true;
    }
    return false;
}

bool hmd_memory_write_uint64_hex(char *buffer, int length, uint64_t val) {
    char buf[128];
    memset(buf,0,sizeof(buf));
    char *c = &buf[126];
    do {
        *c = hmd_crash_hex_array[val % 16];
        c--;
    } while ((val /= 16) != 0);
    c++;
    if (strlen(c)+1 <= length) {
        memcpy(buffer, c, strlen(c)+1);
        return true;
    }
    return false;
}
