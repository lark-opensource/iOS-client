//
//  HMDCrashSDKLog.c
//  CaptainAllred
//
//  Created by sunrunwang on 2019/7/10.
//  Copyright © 2019 sunrunwang. All rights reserved.
//

#include <stdio.h>
#include <limits.h>
#include <stdarg.h>
#include "HMDCrashSDKLog.h"
#include "HMDCrashFileBuffer.h"
#include <string.h>

static FileBuffer sdk;

bool OpenSDK(const char *path) {
    return (sdk = hmd_file_open_buffer(path)) != FileBufferInvalid;
}

static void internal_log(const char *format, va_list args) {
    unsigned long len = strlen(format);
    char buf[32];
    memset(buf, 0, sizeof(buf));
    int buf_len = 0;
    bool format_valid = true;
    for (int i = 0; i < len; i++) {
        char c = format[i];
        if (format_valid && c == '%') {
            
            if (buf_len > 0) {
                hmd_file_write_string(sdk, buf);
                memset(buf, 0, sizeof(buf));
                buf_len = 0;
            }

            if (i + 1 < len) {
                char s = format[i+1];
                switch (s) {
                    case 'd':
                    {
                        int val = va_arg(args, int);
                        hmd_file_write_int64(sdk, val);
                        i++;
                        continue;
                    }
                        break;
                    case 'u':
                    {
                        unsigned int val = va_arg(args, unsigned int);
                        hmd_file_write_uint64(sdk, val);
                        i++;
                        continue;
                    }
                        break;
                    case 's':
                    {
                        char *val = va_arg(args, char *);
                        hmd_file_write_string(sdk, val);
                        i++;
                        continue;
                    }
                        break;
                    case 'p':
                    {
                        void * val = va_arg(args, void *);
                        hmd_file_write_string(sdk, "0x");
                        hmd_file_write_uint64_hex(sdk, (uint64_t)val);
                        i++;
                        continue;
                    }
                        break;
                    case 'x':
                    {
                        int val = va_arg(args, int);
                        hmd_file_write_uint64_hex(sdk, (uint64_t)val);
                        i++;
                        continue;
                    }
                        break;
                    default:
                        format_valid = false;
                        break;
                }
            }
        }
        
        buf[buf_len] = c;
        buf_len += 1;
        if (buf_len >= 31) {
            hmd_file_write_string(sdk, buf);
            memset(buf, 0, sizeof(buf));
            buf_len = 0;
        }
    }
    
    if (buf_len > 0) {
        hmd_file_write_string(sdk, buf);
    }

    hmd_file_write_string(sdk, "\n");
}

void SDKLogBaseStr(const char *format, ...) {
    if (sdk <= 0) {
        return;
    }

    if (format == NULL) {
        format = "";
    }
        
    va_list args;
    va_start(args, format);

    internal_log(format,args);
    
    va_end(args);

}

void SDKLogStr(const char *level, const char *file, int line, const char *format, ...) {
    if (sdk <= 0) {
        return;
    }
    
    if (file) {
        const char* lastFile = strrchr(file, '/');
        if (lastFile != NULL) {
            file = lastFile + 1;
        }
    }

    hmd_file_write_string(sdk, level);
    hmd_file_write_string(sdk, " [");
    hmd_file_write_string(sdk, file);
    hmd_file_write_string(sdk, ":");
    hmd_file_write_uint64(sdk, line);
    hmd_file_write_string(sdk, "] ");

    if (format == NULL) {
        format = "";
    }
        
    va_list args;
    va_start(args, format);

    internal_log(format,args);
    
    va_end(args);
}
