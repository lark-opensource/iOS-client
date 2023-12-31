//
//  CFCrashSafeTool.c
//  TEST
//
//  Created by sunrunwang on 2019/7/2.
//  Copyright © 2019 Bill Sun. All rights reserved.
//

#include <stdio.h>
#include <stddef.h>
#include <limits.h>
#include "hmd_crash_safe_tool.h"
#include "hmd_stack_cursor.h"
#include "hmd_stack_cursor_machine_context.h"
#include "hmd_machine_context.h"
#include "HMDCompactUnwind.hpp"
#include "HMDMacro.h"

#if FILENAME_MAX <= 0
#error FILENAME_MAX <= 0
#endif

char *hmd_reliable_strncpy(char * restrict s1, const char * restrict s2, size_t n) {
    DEBUG_ASSERT(s1 != NULL && s2 != NULL);
    if(s1 != NULL && s2 != NULL) {
        for(size_t index = 0; index < n; index++)
            if((*s1++ = *s2++) == '\0') break;
    }
    return s1;
}

size_t hmd_reliable_strlen(const char *str) {
    DEBUG_ASSERT(str != NULL);
    if(str != NULL) {
        const char *current = str;
        while(*current++){
        }
        return (size_t)(current - str) - 1;
    }
    return 0u;
}

const char *hmd_reliable_strrchr(const char *str, int ch) {
    if(str != NULL && ch <= UCHAR_MAX) {
        size_t len = hmd_reliable_strlen(str);
        for(size_t count = len; count > 0; count--)
            if(str[count - 1] == ch)
                return str + count - 1;
    }
    return NULL;
}

char *hmd_reliable_basename(const char *str) {
    if(str == NULL || *str == '\0') return ".";
    if(*str == '/' && str[1] == '\0') return "/";
    const char *temp = hmd_reliable_strrchr(str, '/');
    if(temp == NULL) temp = str;
    else temp = temp + 1;
    static char local[FILENAME_MAX];
    hmd_reliable_strncpy(local, temp, FILENAME_MAX - 1);
    local[FILENAME_MAX - 1] = '\0';
    return local;
}

char *hmd_reliable_dirname(const char *str) {
    const char *temp;
    if(str == NULL || *str == '\0' || (temp = hmd_reliable_strrchr(str, '/')) == NULL) return ".";
    static char local[FILENAME_MAX];
    size_t length = temp - str;
    if(length + 1 > FILENAME_MAX) length = FILENAME_MAX - 1;
    hmd_reliable_strncpy(local, str, length);
    local[length] = '\0';
    return local;
}

static int hmd_internal_reliable_backtrace(void** buffer,int length,bool fast,int skipdepth) {
    if (buffer == NULL || length <= 0) {
        return 0;
    }
    hmd_stack_cursor cursor;
    KSMC_NEW_CONTEXT(context);
    
    hmd_thread_state_t* const state = &context->state;
    hmdmc_get_current_thread_state(state);

    hmdsc_initWithMachineContext(&cursor, context);
    
    cursor.fast_unwind = fast;
    
    skipdepth++;
    
    int index = 0;
    while (index < length && cursor.advanceCursor(&cursor)) {
        if (skipdepth > 0) {
            skipdepth--;
            continue;
        }
        buffer[index] = (void *)cursor.stackEntry.address;
        index++;
    }
    GCC_FORCE_NO_OPTIMIZATION
    return index;
}

int hmd_reliable_backtrace(void** buffer,int length) {
    int ret = hmd_internal_reliable_backtrace(buffer,length,false,1);
    GCC_FORCE_NO_OPTIMIZATION
    return ret;
}

int hmd_reliable_fast_backtrace(void** buffer,int length) {
    int ret = hmd_internal_reliable_backtrace(buffer,length,true,1);
    GCC_FORCE_NO_OPTIMIZATION
    return ret;
}

bool hmd_reliable_has_prefix(const char *str, const char *prefix)
{
    if (prefix == NULL || str == NULL) {
        return false;
    }
    
    size_t pre_len = strlen(prefix);
    if (pre_len > strlen(str)) {
        return false;
    }
    return strncmp(prefix, str, pre_len) == 0;
}

bool hmd_reliable_has_suffix(const char *str, const char *suffix)
{
    if (!str || !suffix)
        return false;
    size_t lenstr = strlen(str);
    size_t lensuffix = strlen(suffix);
    if (lensuffix >  lenstr)
        return false;
    return strncmp(str + lenstr - lensuffix, suffix, lensuffix) == 0;
}
